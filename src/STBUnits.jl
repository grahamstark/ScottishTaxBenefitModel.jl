module STBUnits
    #
    # Not Used presently - initial attempt to use Unitful to model all the values in hhlds and parameters. 
    #
    #
    using Unitful

    @unit money "GBP" Money 1u"£" false
    @unit pA "PA" PA 365u"£" false;
    @unit rate "r" Rate 1u"r" false

end
