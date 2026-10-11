// Isolated diagnostic fixture only. Never upload this binary to App Store Connect.
import CloudKit
import CoreData
import Observation
import Security
import SwiftData
import SwiftUI

@main
struct NevernoteApp: App {
    var body: some Scene {
        WindowGroup("NeverNote schema diagnostic") { SchemaDiagnosticView() }
            .defaultSize(width: 640, height: 460)
    }
}

private struct SchemaDiagnosticView: View {
    @State private var state = SchemaDiagnosticState()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("NeverNote schema diagnostic", systemImage: "wrench.and.screwdriver").font(.title2.bold())
            Text("Development tool — not the shipping app").foregroundStyle(.secondary)
            Text(NevernoteCloudKit.containerIdentifier).font(.callout.monospaced()).textSelection(.enabled)
            Text(state.signingStatus).textSelection(.enabled)
            Text(state.accountStatus).font(.headline).textSelection(.enabled)
            if state.busy { ProgressView() }
            HStack {
                Button("Check account") { Task { await state.checkAccount() } }.disabled(state.busy)
                Button("Initialize development schema") { state.confirmInitialization = true }.disabled(!state.canInitialize)
            }
            Text(state.result).font(.callout).textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(24).frame(minWidth: 580, minHeight: 400)
        .confirmationDialog("Initialize the development schema?", isPresented: $state.confirmInitialization) {
            Button("Initialize development schema") { Task { await state.initializeSchema() } }
        } message: {
            Text("Core Data will upload generated sample records, then remove them. This uses a new temporary store and does not open any existing notes. Production is unchanged.")
        }
    }
}

@MainActor @Observable
private final class SchemaDiagnosticState {
    var signingStatus = "Signing not checked"
    var accountStatus = "Account not checked"
    var result = "Check account first. Schema initialization is a separate action."
    var busy = false
    var confirmInitialization = false
    private var signedDevelopment = false
    private var available = false
    var canInitialize: Bool { signedDevelopment && available && !busy }

    func checkAccount() async {
        busy = true; available = false; signedDevelopment = false
        defer { busy = false }
        do {
            let signing = try SigningCheck.inspect()
            signingStatus = signing.summary
            signedDevelopment = signing.development
            let status = try await CKContainer(identifier: NevernoteCloudKit.containerIdentifier).accountStatus()
            available = status == .available
            switch status {
            case .available: accountStatus = "iCloud account available"
            case .noAccount: accountStatus = "No iCloud account on this Mac"
            case .restricted: accountStatus = "iCloud account restricted"
            case .couldNotDetermine: accountStatus = "iCloud account status could not be determined"
            case .temporarilyUnavailable: accountStatus = "iCloud account temporarily unavailable"
            @unknown default: accountStatus = "Unknown iCloud account status"
            }
            if !signedDevelopment { result = "An explicit Development iCloud entitlement is required before initialization." }
        } catch { accountStatus = "Check failed"; result = error.localizedDescription }
    }

    func initializeSchema() async {
        guard canInitialize else { return }
        busy = true
        result = "Initializing the development schema in a fresh temporary store…"
        defer { busy = false }
        do {
            let signing = try SigningCheck.inspect()
            guard signing.development else { throw DiagnosticError("Development signing is not verified.") }
            guard try await CKContainer(identifier: NevernoteCloudKit.containerIdentifier).accountStatus() == .available else {
                available = false
                throw DiagnosticError("The iCloud account is no longer available.")
            }
            let storePath = try await Task.detached(priority: .userInitiated) { try SchemaInitializer.run() }.value
            result = "Development initialization completed. Verify the schema in CloudKit Console before deploying. Temporary fixture: " + storePath
        } catch { result = "Initialization failed: " + error.localizedDescription }
    }
}

private enum SigningCheck {
    struct Result { let summary: String; let development: Bool }
    static func inspect() throws -> Result {
        let bundle = Bundle.main
        guard bundle.bundleIdentifier == "com.nathanfennel.NeverNote" else { throw DiagnosticError("Unexpected diagnostic bundle identifier.") }
        guard FileManager.default.fileExists(atPath: bundle.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile").path) else {
            throw DiagnosticError("A matching macOS development provisioning profile is missing.")
        }
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundle.bundleURL as CFURL, [], &code) == errSecSuccess, let code,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), nil) == errSecSuccess else {
            throw DiagnosticError("The diagnostic app's strict signature check failed.")
        }
        var information: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let info = information as? [String: Any],
              info[kSecCodeInfoTeamIdentifier as String] as? String == "EJLR2RPSV2",
              let entitlements = info[kSecCodeInfoEntitlementsDict as String] as? [String: Any],
              (entitlements["com.apple.developer.icloud-container-identifiers"] as? [String])?.contains(NevernoteCloudKit.containerIdentifier) == true,
              (entitlements["com.apple.developer.icloud-services"] as? [String])?.contains("CloudKit") == true,
              entitlements["com.apple.security.get-task-allow"] as? Bool == true else {
            throw DiagnosticError("Expected NeverNote development team and CloudKit entitlements are not present.")
        }
        let environment = entitlements["com.apple.developer.icloud-container-environment"] as? String
        return Result(summary: "Signed team EJLR2RPSV2 • iCloud environment: " + (environment ?? "unspecified"), development: environment == "Development")
    }
}

private enum SchemaInitializer {
    static func run() throws -> String {
        try autoreleasepool {
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [NoteDocument.self]) else { throw DiagnosticError("The original SwiftData model could not be converted.") }
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NeverNoteSchemaDiagnostic", isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let storeURL = directory.appendingPathComponent("synthetic-schema.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldAddStoreAsynchronously = false
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: NevernoteCloudKit.containerIdentifier)
            options.databaseScope = .private
            description.cloudKitContainerOptions = options
            let container = NSPersistentCloudKitContainer(name: "NeverNoteSchemaDiagnostic", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: Error?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError { throw loadError }
            defer { for store in container.persistentStoreCoordinator.persistentStores { try? container.persistentStoreCoordinator.remove(store) } }
            // Apple generates every serialized field; no existing note is inserted or copied.
            try container.initializeCloudKitSchema(options: [.printSchema])
            return storeURL.path
        }
    }
}

private struct DiagnosticError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
