module Monitor
    #
    # just a wee thing to share will web apps
    # to make progress bars, etc.


    using Observables

    struct Progress
        phase  :: String
        thread :: Int
        count  :: Int
        step   :: Int
    end

    # run_obs = Observable( Progress("", 0, 0 ))

end