var express = require('express')
var path = require('path');
var bodyParser = require('body-parser')
var routes = require('./api/routes')

var app = express();

app.use(function(req,res,next){
    console.log(req.method,req.url);
    next();
})

app.use(express.static(path.join(__dirname,'public')))

app.use(bodyParser.urlencoded({extended : false}));

app.use('/api',routes);

//app.set('port',3000);

var port = process.env.PORT || 3000;

var server = app.listen(port,function(){
    var port = server.address().port;
    console.log('some one hit you at '+port);
});
