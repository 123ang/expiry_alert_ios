import Foundation

extension String {
    /// Rewrites http to https so iOS App Transport Security allows loading the image.
    var secureImageURLString: String {
        guard lowercased().hasPrefix("http://") else { return self }
        return "https://" + dropFirst(7)
    }
}
