;; ProofStack: Trustless Reputation Engine
;; A decentralized reputation and participation scoring framework for community governance on the Stacks blockchain
(define-constant owner tx-sender)
(define-constant error-owner-only (err u100))
(define-constant error-participant-not-found (err u101))
(define-constant error-permission-denied (err u102))
(define-constant error-already-exists (err u103))
(define-constant error-missing-profile (err u104))
(define-constant error-invalid-contribution (err u105))
;; Data Maps
(define-map participant-stats 
    principal 
    {
        reputation-score: uint,
        proposals: uint,
        votes: uint,
        last-contribution: uint,
        completions: uint
    }
)
(define-map contribution-types
    {contribution: (string-ascii 24)}
    {reward: uint}
)
;; Initialize default activity point values
(map-set contribution-types {contribution: "initiative"} {reward: u10})
(map-set contribution-types {contribution: "decision"} {reward: u5})
(map-set contribution-types {contribution: "task"} {reward: u15})
;; Public functions
(define-public (join-network)
    (begin
        (asserts! (is-none (get-participant-profile tx-sender)) error-already-exists)
        (ok (map-set participant-stats tx-sender {
            reputation-score: u0,
            proposals: u0,
            votes: u0,
            last-contribution: stacks-block-height,
            completions: u0
        }))
    )
)
(define-public (record-proposal)
    (let (
        (profile (unwrap! (get-participant-profile tx-sender) error-missing-profile))
        (reward (get reward (unwrap! (map-get? contribution-types {contribution: "initiative"}) error-invalid-contribution)))
    )
    (ok (map-set participant-stats tx-sender (merge profile {
        reputation-score: (+ (get reputation-score profile) reward),
        proposals: (+ (get proposals profile) u1),
        last-contribution: stacks-block-height
    })))
    )
)
(define-public (record-vote)
    (let (
        (profile (unwrap! (get-participant-profile tx-sender) error-missing-profile))
        (reward (get reward (unwrap! (map-get? contribution-types {contribution: "decision"}) error-invalid-contribution)))
    )
    (ok (map-set participant-stats tx-sender (merge profile {
        reputation-score: (+ (get reputation-score profile) reward),
        votes: (+ (get votes profile) u1),
        last-contribution: stacks-block-height
    })))
    )
)
(define-public (record-completion)
    (let (
        (profile (unwrap! (get-participant-profile tx-sender) error-missing-profile))
        (reward (get reward (unwrap! (map-get? contribution-types {contribution: "task"}) error-invalid-contribution)))
    )
    (ok (map-set participant-stats tx-sender (merge profile {
        reputation-score: (+ (get reputation-score profile) reward),
        completions: (+ (get completions profile) u1),
        last-contribution: stacks-block-height
    })))
    )
)
;; Admin functions
(define-public (update-contribution-reward (contribution (string-ascii 24)) (new-reward uint))
    (begin
        (asserts! (is-eq tx-sender owner) error-owner-only)
        (ok (map-set contribution-types {contribution: contribution} {reward: new-reward}))
    )
)
;; Read-only functions
(define-read-only (get-participant-profile (participant principal))
    (map-get? participant-stats participant)
)
(define-read-only (get-contribution-reward (contribution (string-ascii 24)))
    (map-get? contribution-types {contribution: contribution})
)
;; Private helper function
(define-private (calculate-decay (base uint) (period uint))
    (let (
        (attenuation (/ period u1000))
    )
    (if (> attenuation u0)
        (/ base attenuation)
        base
    ))
)
;; Merit calculation with time-based decay
(define-read-only (get-active-reputation (participant principal))
    (let (
        (profile (unwrap! (get-participant-profile participant) error-participant-not-found))
        (dormancy (- stacks-block-height (get last-contribution profile)))
    )
    (ok (calculate-decay (get reputation-score profile) dormancy))
    )
)