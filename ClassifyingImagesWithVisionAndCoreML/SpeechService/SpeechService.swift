//
//  SpeechService.swift
//  Vision + CoreML
//
//  Created by Pranav Kallem on 4/5/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import AVKit

class SpeechService: NSObject {
    
    static let shared = SpeechService()
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    func startSpeech ( text: String) {
        self.stopSpeeching()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 1
        speechSynthesizer.speak(utterance)
 
    }
    
    func stopSpeeching() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
