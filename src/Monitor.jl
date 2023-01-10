module Monitor
    #
    # This module is a struct for a listener for model run progress,
    # 
    # just a wee thing to share will web apps
    # to make progress bars, etc.
    using Observables
    using UUIDs

    export Progress

    struct Progress
        uuid   :: UUID
        phase  :: String
        thread :: Int
        count  :: Int
        step   :: Int
        size   :: Int
    end

    # run_obs = Observable( Progress("", 0, 0 ))

end
