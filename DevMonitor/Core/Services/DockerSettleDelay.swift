import Foundation

enum DockerSettleDelay {
    /// After starting or stopping a single container: Docker needs a beat to
    /// settle into its final "running"/"exited" state rather than a
    /// transient one.
    static let containerStateChange: UInt64 = 800_000_000

    /// After a container is deleted, a container is created, or an image is
    /// deleted: enough time for the item to actually disappear/appear in
    /// Docker's own listing before this app re-fetches it.
    static let listMutation: UInt64 = 400_000_000

    /// After `docker compose up`: starting every service in a stack (image
    /// pulls if needed, network + multiple container creation) takes longer
    /// to settle than a single container.
    static let composeUp: UInt64 = 1_500_000_000

    /// After `docker compose down`: stopping and removing every container
    /// plus the stack's network is typically slower than bringing it up.
    static let composeDown: UInt64 = 2_500_000_000
    
    /// How long the "Done" progress message stays on screen before the pull
    /// banner clears — a UI pacing pause so the user can actually read it,
    /// not a Docker-settle delay like DockerSettleDelay's cases.
    static let pullDoneMessageDuration: UInt64 = 800_000_000
}
