import AVFoundation
import Observation
import Photos

enum NoteImageCombinedPermission {
    case notDetermined
    case cameraOnly
    case photoOnly
    case both
    case denied
}

@Observable
final class NoteImagePermissionManager {
    private(set) var state: NoteImageCombinedPermission = .notDetermined

    func refreshStatus() {
        #if os(macOS)
        state = .photoOnly
        return
        #endif
        let cam = AVCaptureDevice.authorizationStatus(for: .video)
        let photo = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        let camGranted = cam == .authorized
        let photoGranted = photo == .authorized || photo == .limited
        let camDenied = cam == .denied || cam == .restricted
        let photoDenied = photo == .denied || photo == .restricted

        if camGranted && photoGranted {
            state = .both
        } else if camGranted {
            state = .cameraOnly
        } else if photoGranted {
            state = .photoOnly
        } else if camDenied && photoDenied {
            state = .denied
        } else {
            state = .notDetermined
        }
    }

    func requestCamera() async {
        await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run { refreshStatus() }
    }

    func requestPhotoLibrary() async {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run { refreshStatus() }
    }

    func requestBoth() async {
        await requestCamera()
        await requestPhotoLibrary()
    }
}
