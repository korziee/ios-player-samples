//
//  ViewController.swift
//  BasicSSAIPlayer
//
//  Created by Jeremy Blaker on 3/18/19.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK
import BrightcoveSSAI

// ** Customize these values with your own account information **
struct Constants {
    static let AccountID = "5434391461001"
    static let PlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
    static let VideoId = "5702141808001"
    static let AdConfigId = "0e0bbcd1-bba0-45bf-a986-1288e5f9fc85"
}

class ViewController: UIViewController {
    @IBOutlet weak var videoContainerView: UIView!
    
    private lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: Constants.AccountID, policyKey: Constants.PlaybackServicePolicyKey)
        return BCOVPlaybackService(requestFactory: factory)
    }()
    
    private lazy var fairplayAuthProxy: BCOVFPSBrightcoveAuthProxy? = {
        guard let _authProxy = BCOVFPSBrightcoveAuthProxy(publisherId: nil, applicationId: nil) else {
            return nil
        }
        return _authProxy
    }()
    
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let manager = BCOVPlayerSDKManager.shared(), let fairplayAuthProxy = fairplayAuthProxy else {
            return nil
        }
        
        let fairplaySessionProvider = manager.createFairPlaySessionProvider(with: fairplayAuthProxy, upstreamSessionProvider: nil)
        let ssaiSessionProvider = manager.createSSAISessionProvider(withUpstreamSessionProvider: fairplaySessionProvider)
        
        guard let _playbackController = manager.createPlaybackController(with: ssaiSessionProvider, viewStrategy: nil) else {
            return nil
        }
        
        _playbackController.delegate = self
        _playbackController.isAutoPlay = true
        
        self.playerView?.playbackController = _playbackController
        
        return _playbackController
    }()
    
    private lazy var playerView: BCOVTVPlayerView? = {
        let options = BCOVTVPlayerViewOptions()
        options.presentingViewController = self
        //options.hideControlsInterval = 3000
        //options.hideControlsAnimationDuration = 0.2
        
        // Create PlayerUI views with normal VOD controls.
        guard let _playerView = BCOVTVPlayerView(options: options) else {
            return nil
        }
        
        // Add to parent view
        self.videoContainerView.addSubview(_playerView)
        _playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _playerView.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor),
            _playerView.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor),
            _playerView.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor),
            _playerView.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
            ])
        
        return _playerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestContentFromPlaybackService()
    }
    
    private func requestContentFromPlaybackService() {
        /**
         * This token has the following claims:
         * {
             "pkid": "d03d6ec5-ba2a-46a1-9778-c2fd162291a4",
             "accid": "4468173393001",
             "conid": "6192074705001",
             "pro": "fairplay",
             "vod": {
               "ssai": "33a3fe9c-e360-47ba-b957-bec336bc69f7"
             },
             "iat": 1605669932
           }
         *
         * It has been configured not to expire.
         */
        let bcov_auth_token = "ewoJInR5cGUiOiAiSldUIiwKCSJhbGciOiAiUlMyNTYiCn0.ewogICJwa2lkIjogImQwM2Q2ZWM1LWJhMmEtNDZhMS05Nzc4LWMyZmQxNjIyOTFhNCIsCiAgImFjY2lkIjogIjQ0NjgxNzMzOTMwMDEiLAogICJjb25pZCI6ICI2MTkyMDc0NzA1MDAxIiwKICAicHJvIjogImZhaXJwbGF5IiwKICAidm9kIjogewogICAgInNzYWkiOiAiMzNhM2ZlOWMtZTM2MC00N2JhLWI5NTctYmVjMzM2YmM2OWY3IgogIH0sCiAgImlhdCI6IDE2MDU2Njk5MzIKfQ.AudqKK_zoXwJ0gIOqM_dGcn9E2y9H7Q1c2vnsKI25ROIdGU-MajWvBwrdwBgopabbS3xCWPXmPQcmY2dF2EvISco2zHDAddQf_TcvEJ7DzUaH_rClL7kA1ij5AhtyrrCMnVmpUCKTQFD1Fud4cdjJ6rSWhmT0b5KxU7HXEKVsf30h31l_N24vcjzME7CPbkJOM7HkEVaDdUvvFXJEgsjdiLjNQRxN60F0_BJuiYVK5hWI1jn93uWE9MWvUULcqPt0hGlCbl3PgeUvdiX8BO62uYAr-u612OsS8DpATxKheoLVbeXdEUjXrIxC8MZl9OAm8VNaT-gr2PeiF1ICY7vhg"

        let videoId = "6192074705001"
        let accountId = "4468173393001"
        
        let staticHlsVmapUrl = URL(string: "https://playback.brightcovecdn.com/playback/v1/accounts/\(accountId)/videos/\(videoId)/hls.vmap?bcov_auth=\(bcov_auth_token)")

        let video = BCOVVideo(hlsSourceURL: staticHlsVmapUrl)

        self.playbackController?.setVideos([video] as NSFastEnumeration)
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        guard let _playerView = self.playerView else {
            return []
        }
        return [_playerView]
    }
    
    override var preferredFocusedView: UIView? {
        return self.playerView
    }
}

// MARK: - BCOVPlaybackControllerDelegate
extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
}

// MARK: - BCOVPlaybackControllerAdsDelegate
extension ViewController: BCOVPlaybackControllerAdsDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter adSequence: BCOVAdSequence!) {
        print("ViewController Debug - Entering ad sequence")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAdSequence adSequence: BCOVAdSequence!) {
        print("ViewController Debug - Exiting ad sequence")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter ad: BCOVAd!) {
        print("ViewController Debug - Entering ad")
    }
    
    func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAd ad: BCOVAd!) {
        print("ViewController Debug - Exiting ad")
    }
}


