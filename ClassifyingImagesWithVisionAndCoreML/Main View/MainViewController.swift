/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that selects an image and makes a prediction using Vision and Core ML.
*/

import UIKit
import WebKit

class MainViewController: UIViewController {
    var firstRun = true

    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    let imagePredictor = ImagePredictor()

    /// The largest number of predictions the main view controller displays the user.
    let predictionsToShow = 2

    let webView = WKWebView()
    
    // MARK: Main storyboard outlets
    @IBOutlet weak var startupPrompts: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    override func becomeFirstResponder() -> Bool {
        return true
    }

    
    //Emergency contact
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        if motion == .motionShake {
            print("Shake Gesture Detected")
            SpeechService.shared.startSpeech(text: "Emergency Contact")

            let url: NSURL = URL(string: "TEL://9199850317")! as NSURL
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            
        }
    }
    

    
}



extension MainViewController {
    // MARK: Main storyboard actions
    /// The method the storyboard calls when the user one-finger taps the screen.
    @IBAction func longPress() {
        // Show options for the source picker only if the camera is available.
        SpeechService.shared.startSpeech(text: "Ready to scan")

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            present(photoPicker, animated: false)
            return
        }

        present(cameraPicker, animated: false)
        
        
//        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
//            present(SecondViewController(), animated: false)
//            return
//        }
//
//        present(SecondViewController(), animated: false)
    }

    /// The method the storyboard calls when the user two-finger taps the screen.

    //For photo library thing
    //    @IBAction func threeFingerSingleTap() {
//        present(photoPicker, animated: false)
//    }
    
    @IBAction func twoFingerSingleTap() {
        present(hearingAndSpeech(), animated: true)
    }
    
    @IBAction func pinch() {
        present(cognitive(), animated: true)
    }
}

class hearingAndSpeech: MainViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        
        guard let url = URL(string: "https://translate.google.com/#ja/en/hello") else {
            return
            }
        webView.load(URLRequest(url: url))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
}



class cognitive: MainViewController {
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        
      
        webView.loadHTMLString("<!DOCTYPE html><html><body> <br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><div><iframe src='https://puzzel.org/en/slidingpuzzle/embed?p=-N-04_4X0HSDbQ-SGXuL' width='1600' height='1600' frameborder='0'></iframe></div> </body></html>", baseURL: nil)
        
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.isMultipleTouchEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    
}



extension MainViewController {
    // MARK: Main storyboard updates
    /// Updates the storyboard's image view.
    /// - Parameter image: An image.
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    /// Updates the storyboard's prediction label.
    /// - Parameter message: A prediction or message string.
    /// - Tag: updatePredictionLabel
    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.predictionLabel.text = message
        }

        if firstRun {
            DispatchQueue.main.async {
                self.firstRun = false
                self.predictionLabel.superview?.isHidden = false
                self.startupPrompts.isHidden = true
            }
        }
    }
    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
    /// - Parameter photo: A photo from the camera or photo library.
    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("Making predictions for the photo...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }

}

extension MainViewController {
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
            SpeechService.shared.startSpeech(text: "Unknown object")

        }
    }

    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.joined(separator: "\n")
        updatePredictionLabel(predictionString)
        SpeechService.shared.startSpeech(text: predictionString + "..............Press and hold to try again")
        
    }

    /// Converts a prediction's observations into human-readable strings.
    /// - Parameter observations: The classification observations from a Vision request.
    /// - Tag: formatPredictions
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification

            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }

            return "\(name) - \(prediction.confidencePercentage)%"
        }

        return topPredictions
    }
}
