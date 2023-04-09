import UIKit
import Combine

class ImageSeriesLooper {
    
    init(seriasAnimatorList: [ImageSeriesAnimator],
         backgroundImageView: UIImageView,
         middleImageView: UIImageView,
         foregroundImageView: UIImageView) {
        
        self.seriasAnimatorList = LoopedList(list: seriasAnimatorList)
        self.backgroundImageView = backgroundImageView
        self.middleImageView = middleImageView
        self.foregroundImageView = foregroundImageView
    }
    
    // MARK: Private
    private let seriasAnimatorList: LoopedList<ImageSeriesAnimator>
    private weak var backgroundImageView: UIImageView!
    private weak var middleImageView: UIImageView!
    private weak var foregroundImageView: UIImageView!
    private var animatorCancellable: AnyCancellable?
}

// MARK: - Public interface
extension ImageSeriesLooper {
    
    @MainActor
    func start() {
        next()
    }
    
    func stop() {
        animatorCancellable?.cancel()
        animatorCancellable = nil
    }
}

// MARK: - Private
private extension ImageSeriesLooper {
    
    func next() {
        animatorCancellable?.cancel()
        scheduleNextAnimation()
    }
    
    func scheduleNextAnimation() {
        let delay = TimeInterval.random(in: 1...2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.startNextAnimation()
        }
    }
    
    func startNextAnimation() {
        guard let currentAnimator = try? seriasAnimatorList.current() else {
            fatalError()
        }
        
        animatorCancellable = currentAnimator.animate(
            backgroundImageView: backgroundImageView,
            middleImageView: middleImageView,
            foregroundImageView: foregroundImageView
        ).sink { [weak self] _ in
            self?.seriasAnimatorList.next()
            self?.next()
        }
    }
}

class LoopedList<Item> {
    
    init(list: [Item]) {
        self.list = list
    }
    
    // MARK: Private
    private let list: [Item]
    private var currentIndex: Int = -1
}

extension LoopedList {

    func current() throws -> Item {
        guard currentIndex > -1 else {
            return next()
        }
        return list[currentIndex]
    }
    
    @discardableResult
    func next() -> Item {
        
        currentIndex = (currentIndex + 1) % list.count
        return list[currentIndex]
    }
}
