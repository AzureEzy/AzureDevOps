var hotelData = require('../data/hotel-data.json');

module.exports.adpGetAllHotel = function(req,res){
    console.log('get the json');
    console.log(req.query);

    var offset = 0;
    var count = 5;

    if(req.query && req.query.offset){
        offset = parseInt(req.query.offset,10);
    }
    if(req.query && req.query.count){
        offset = parseInt(req.query.count,10);
    }

    var returnData = hotelData.slice(offset,offset+count);

    res
        .status(200)
        .json(returnData);
};

 module.exports.adpGetOne = function(req,res){
    var hotelId = req.params.hotelId;
    var thisHotel = hotelData[hotelId];
    console.log('get hotelId',hotelId);
    res
        .status(200)
        .json(thisHotel);
};

module.exports.adpAddOne = function(req,res){
    console.log("POST new hotel");
    console.log(req.body);
    res
        .status(200)
        .json(req.body);
}