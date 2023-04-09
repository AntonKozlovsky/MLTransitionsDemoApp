import UIKit
import Combine

class ImageSeriesShakeAnimator {
    
    init(
        imageSeries: ImageSeries
    ) {
        self.imageSeries = imageSeries
    }
    
    // MARK: - Private
    private let completionSubject = PassthroughSubject<Bool, Never>()
    private let imageSeries: ImageSeries
    private var stepIndex: Int = 0
}

extension ImageSeriesShakeAnimator: ImageSeriesAnimator {
    
    func animate(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) -> AnyPublisher<Bool, Never> {
        
        next(backgroundImageView: backgroundImageView,
             middleImageView: middleImageView,
             foregroundImageView: foregroundImageView)
        return completionSubject.eraseToAnyPublisher()
    }
}

private extension ImageSeriesShakeAnimator {
    
    func next(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) {
        
        switch stepIndex {
        case 0:
            middleImageView.image = imageSeries.backgroundImage
        case 1:
            setStep1(backgroundImageView: backgroundImageView,
                     middleImageView: middleImageView,
                     foregroundImageView: foregroundImageView)
        case 2:
            setStep2(backgroundImageView: backgroundImageView,
                     middleImageView: middleImageView,
                     foregroundImageView: foregroundImageView)
        case 3:
            finish(backgroundImageView: backgroundImageView,
                   middleImageView: middleImageView,
                   foregroundImageView: foregroundImageView)
        default:
            break
        }
        
        stepIndex = (stepIndex + 1) % 4
        
        if stepIndex == 0 {
            completionSubject.send(true)
        } else {
            scheduleUpdate(backgroundImageView: backgroundImageView,
                           middleImageView: middleImageView,
                           foregroundImageView: foregroundImageView)
        }
    }
    
    func scheduleUpdate(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) {
        
        let delay = TimeInterval.random(in: 0.1...0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.next(backgroundImageView: backgroundImageView,
                      middleImageView: middleImageView,
                      foregroundImageView: foregroundImageView)
        }
    }
    
    func finish(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) {
        
        middleImageView.reset()
        foregroundImageView.reset()
        backgroundImageView.image = imageSeries.originalImage
    }
}

// MARK: - Steps
private extension ImageSeriesShakeAnimator {
    
    func setStep1(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) {
        
        foregroundImageView.transform = .identity.rotated(by: CGFloat.pi / 30)
        foregroundImageView.image = imageSeries.silhouetteImage
        backgroundImageView.reset()
    }
    
    func setStep2(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) {
        
        foregroundImageView.transform = .identity.rotated(by: -CGFloat.pi / 20)
        foregroundImageView.image = imageSeries.silhouetteImage
        backgroundImageView.reset()
    }
}
