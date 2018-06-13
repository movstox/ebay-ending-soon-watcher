if process.env.NODE_ENV != 'production'
  require('dotenv').config()

#Lets require/import the HTTP module
restify = require('restify')
trim = require('trim')
request = require('request')
cheerio = require('cheerio')
server = restify.createServer(
  name: 'ebay-ending-watcher'
  version: '1.0.0')
# add any additional custom server configuration
server.use restify.acceptParser(server.acceptable)
server.use restify.queryParser()
server.use restify.bodyParser()
server.use (req,res,next) ->
    res.header("Access-Control-Allow-Origin", "*")
    res.header("Access-Control-Allow-Headers", "X-Requested-With")
    next()
server.get '/amazon-offer/:itemId', (req, res, next) ->
  search_url = "http://www.amazon.#{req.params.domain || 'com'}/gp/offer-listing/#{req.params.itemId}/ref=dp_olp_all_mbc?ie=UTF8&condition=all"
  console.log search_url
  request search_url, (error, response, body) ->
    console.log response
    if response.statusCode == 200
      $ = cheerio.load(body)
      offersData = for ebayListing in $('.olpOffer')[..5] # take 5 items
        offerPriceText = trim($(ebayListing).find('.olpOfferPrice').text())
        currency =
          switch
            when offerPriceText.match /EUR/ then 'EUR'
            when offerPriceText.match /^\$/ then 'USD'
            when offerPriceText.match /^£/ then 'GBP'
            else null
        isUSA = (currency == 'USD')
        isBritain = (currency == 'GBP')
        price =
          switch
            when isBritain then parseFloat(offerPriceText.match(/[\d,]+/)[0].replace(/,/,''))
            when isUSA then parseFloat(offerPriceText.replace(/[^0-9\.-]+/g,""))
            else parseFloat(offerPriceText.match(/[\d\.]+/)[0].replace(/\./,''))
        sellerInformation =  trim($(ebayListing).find('.olpSellerColumn').text())
        sellerRatingCount = sellerInformation.match(/\((\d+)/)
        sellerRatingCount = parseFloat(if sellerRatingCount then sellerRatingCount[1] else 0)
        sellerRatingPct = sellerInformation.match(/\d+%/)
        sellerRatingPct = parseFloat(if sellerRatingPct then sellerRatingPct[0] else '0')

        {
          sellerRatingPct: sellerRatingPct
          sellerRatingCount: sellerRatingCount
          price: price
          currency: currency
          condition: trim($(ebayListing).find('.olpConditionColumn .olpCondition').text())
          sellerInformation: sellerInformation
        }
      res.send({
        id: req.params.itemId,
        title: trim($('#olpProductDetails h1').text()),
        itemListingUrl: search_url,
        offersData: offersData
      })
    else
      res.send({error: res.statusCode})

topFiveEbayItems = (jQuery) -> jQuery('.s-item')[..5]

extractEbayListingData = (jQuery, ebayListing)->
  newListingFlag = jQuery(ebayListing).find('.LIGHT_HIGHLIGHT').text() == 'New Listing'
  buyItNowFlag = (jQuery(ebayListing).find('.s-item__purchase-options').text() == 'Buy It Now')
  bids = parseInt(jQuery(ebayListing).find('.s-item__bids ').text())
  {
    title: trim(jQuery(ebayListing).find('h3.s-item__title').text())
    buyItNowFlag: buyItNowFlag
    newListingFlag: newListingFlag
    bids: bids
    price: parseFloat(trim(jQuery(ebayListing).find('.s-item__price').text()).replace(',', '').replace('$',''))
    timeLeftText: jQuery(ebayListing).find('.s-item__time-left').text().split(' left')[0]
    endsAt: parseInt(jQuery(ebayListing).find('.timeleft .timeMs').attr('timems'))
    itemListingUrl: (jQuery(ebayListing).find('.s-item__link').attr('href'))
    itemPictureUrl: (jQuery(ebayListing).find('.s-item__image-img').attr('src'))
  }

server.get '/ebay-new-listings/:name', (req, res, next) ->
  search_url = "http://www.ebay.#{req.params.domain || 'com'}/sch/i.html?_from=R40&_sacat=0&_nkw=#{req.params.name}&_sop=10&_udlo=#{req.params.price_low}&_udhi=#{req.params.price_high}&LH_ItemCondition=1000|1500|3000"

  console.log search_url

  request search_url, (error, response, body) ->
    $ = cheerio.load(body)
    itemsData = for ebayListing in topFiveEbayItems($)
      extractEbayListingData($, ebayListing)
    res.send(itemsData)
  next()

server.get '/ebay-ending-soon/:name', (req, res, next) ->
  lh_complete = req.params.LH_Complete || 0
  lh_sold = req.params.LH_Sold || 0
  lh_bin = req.params.LH_BIN || 0

  search_url = "http://www.ebay.#{req.params.domain || 'com'}/sch/i.html?_from=R40&_sacat=0&_nkw=#{req.params.name}&_sop=1&_udlo=#{req.params.price_low}&_udhi=#{req.params.price_high}&LH_Complete=#{lh_complete}&LH_Sold=#{lh_sold}&LH_BIN=#{lh_bin}&LH_ItemCondition=1000|1500|3000"


  console.log search_url
  request search_url, (error, response, body) ->
    if response.statusCode == 200
      $ = cheerio.load(body)
      itemsData = for ebayListing in topFiveEbayItems($) # take 5 items
        extractEbayListingData($, ebayListing)
          # {
          #     title: trim($(ebayListing).find('h3.lvtitle').text())
          #     price: parseFloat(trim($(ebayListing).find('.lvprice').text()).replace(',', '').replace('$',''))
          #     endsAt: parseInt($(ebayListing).find('.timeleft .timeMs').attr('timems'))
          #     itemListingUrl: ($(ebayListing).find('.lvtitle a').attr('href'))
          #     itemPictureUrl: ($(ebayListing).find('.lvpic img').attr('src'))
          # }
      res.send(itemsData)
    return
  next()

port = process.env.PORT or 5000
server.listen port, ->
  console.log '%s listening at %s', server.name, server.url
  return
