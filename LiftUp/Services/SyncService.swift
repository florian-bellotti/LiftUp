import Foundation
import Network

/// Service de synchronisation avec l'API (préparé pour future implémentation)
final class SyncService: ObservableObject {
    @Published var isOnline = true
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var pendingChangesCount = 0

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    init() {
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    /// Synchronise les changements en attente
    func sync() async throws {
        guard isOnline else {
            throw SyncError.offline
        }

        isSyncing = true
        defer { isSyncing = false }

        // TODO: Implémenter la synchronisation avec l'API
        // 1. Récupérer les changements locaux non synchronisés
        // 2. Envoyer à l'API
        // 3. Récupérer les changements du serveur
        // 4. Merger les conflits
        // 5. Mettre à jour lastSyncDate

        // Simuler un délai de sync
        try await Task.sleep(nanoseconds: 500_000_000)

        lastSyncDate = Date()
        pendingChangesCount = 0
    }

    /// Marque un changement comme en attente de sync
    func markPendingChange() {
        pendingChangesCount += 1
    }

    /// Export des données en JSON (pour backup)
    func exportData() async throws -> Data {
        // TODO: Implémenter l'export
        // Sera utile pour le backup/restore
        return Data()
    }

    /// Import des données depuis JSON
    func importData(_ data: Data) async throws {
        // TODO: Implémenter l'import
    }

    deinit {
        monitor.cancel()
    }
}

enum SyncError: LocalizedError {
    case offline
    case serverError(Int)
    case conflict
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .offline:
            return "Pas de connexion internet"
        case .serverError(let code):
            return "Erreur serveur (\(code))"
        case .conflict:
            return "Conflit de données"
        case .unauthorized:
            return "Non autorisé"
        }
    }
}
