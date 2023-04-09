import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var middleImageView: UIImageView!
    @IBOutlet weak var foregroundImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var imageSeriesManager: ImageSeriesManager!
    private var seriesLooper: ImageSeriesLooper!
    private var player = AACPlayer()
}

// MARK: - Overrides
extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

// MARK: - Setup view
private extension ViewController {

    func setupView() {
        
        do {
            imageSeriesManager = try ImageSeriesManager()
        } catch {
            // TODO: Show error
        }
        
        Task {
            await setupAnimation()
            setupPlayer()
            self.seriesLooper.start()
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    func setupPlayer() {
        
        guard let audioUrl = Bundle.main.url(forResource: "music", withExtension: "aac") else {
            // TODO: Handle error
            assertionFailure()
            return
        }
        
        do {
            try player.play(itemAt: audioUrl)
        } catch {
            // TODO: Show error
            assertionFailure(error.localizedDescription)
        }
    }
    
    func setupAnimation() async {
        
        let seriesImages = await imageSeriesManager.series(from: self.sourceImages())
        
        backgroundImageView.image = seriesImages[0].originalImage
        let animatorList: [ImageSeriesAnimator] = seriesImages.enumerated().map {
            if $0.offset % 2 == 0 {
                return ImageSeriesSerialAnimator(imageSeries: $0.element)
            } else {
                return ImageSeriesShakeAnimator(imageSeries: $0.element)
            }
        }
        
        seriesLooper = ImageSeriesLooper(seriasAnimatorList: animatorList,
                                         backgroundImageView: backgroundImageView,
                                         middleImageView: middleImageView,
                                         foregroundImageView: foregroundImageView)
    }
}

private extension ViewController {
    
    func sourceImages() -> [UIImage] {
        var images: [UIImage] = []
        var image: UIImage?
        var index: Int = 1
        
        repeat {
            image = UIImage(named: "\(index).jpeg")
            if let image {
                images.append(image)
            }
            index += 1
        } while image != nil
        
        return images
    }
}

