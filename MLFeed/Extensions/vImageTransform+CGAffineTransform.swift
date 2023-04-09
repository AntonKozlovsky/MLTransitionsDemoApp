import Accelerate

extension vImage_CGAffineTransform {
    
    init(affineTransform: CGAffineTransform) {

        self.init(
            a: affineTransform.a,
            b: affineTransform.b,
            c: affineTransform.c,
            d: affineTransform.d,
            tx: affineTransform.tx,
            ty: affineTransform.ty
        )
    }
}
