import UIKit
import Combine

class ImageSeriesSerialAnimator {
    
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

extension ImageSeriesSerialAnimator: ImageSeriesAnimator {
    
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

private extension ImageSeriesSerialAnimator {
    
    func next(
        backgroundImageView: UIImageView,
        middleImageView: UIImageView,
        foregroundImageView: UIImageView
    ) {
        
        switch stepIndex {
        case 0:
            foregroundImageView.image = imageSeries.silhouetteImage
        case 1:
            finish(backgroundImageView: backgroundImageView,
                   middleImageView: middleImageView,
                   foregroundImageView: foregroundImageView)
        default:
            break
        }
        
        stepIndex = (stepIndex + 1) % 2
        
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
        middleImageView.image = nil
        foregroundImageView.image = nil
        backgroundImageView.image = imageSeries.originalImage
    }
}
