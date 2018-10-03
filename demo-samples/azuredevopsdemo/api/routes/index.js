var express = require('express')
var router = express.Router();

var ctrladp = require('../controllers/adp.controllers.js')

router
 .route('/json')
 .get(ctrladp.adpGetAllHotel);

module.exports = router;

router
 .route('/json/:hotelId')
 .get(ctrladp.adpGetOne);

 router
    .route('/json/new/')
    .post(ctrladp.adpAddOne);

module.exports = router;