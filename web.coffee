# Description:
#   A simple interaction with the built in HTTP Daemon
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SIMSIMI_API_KEY 
#   HUBOT_WEIXIN_TOKEN   
#
# Commands:
#   None
#
# URLS:
#   /talk/wechat

crypto = require 'crypto'
qs = require 'querystring'
parseString = require('xml2js').parseString
httpsync = require('httpsync')

url = "http://api.simsimi.com/request.p"
hello = 'HI~ 我是卖得了萌, 装得了傻, 哄得了人, 吵得了架, 还说得出笑话~情话的小贱鸡哦~!'
no_result = [
                'O~O~O~OPPA gangnam style'
                '虽然小黄鸡读不懂你的话, 但小黄鸡却能用心感受你对我的爱'
                '说什么呢? 欺负小黄鸡不懂鸟语呀??'
                '是世界变化太快, 还是我不够有才? 为何你说话我不明白?'
                '曾经以为只有机器人才会打非所问, 直到今天看到你说的话, 小黄鸡才明白, 原来人来说话也会让我难以理解'
]
http = require 'http'
express = require 'express'
app = express()

app.get '/talk', (req, res) ->
    message = 'Hello, world!'
    res.send message

checkToken = (req) ->
    query = qs.parse(req._parsedUrl.query)
    token = process.env.HUBOT_WEIXIN_TOKEN
    args = [ token, query.timestamp, query.nonce ]
    args.sort()
    check = args.join ''
    hash = crypto.createHash('sha1').update(check, 'utf8').digest('hex')
    hash == query.signature

app.get "/talk/webchat", (req, res) ->
    query = qs.parse(req._parsedUrl.query)
    token = process.env.HUBOT_WEIXIN_TOKEN
    args = [ token, query.timestamp, query.nonce ]
    args.sort()
    check = args.join ''
    hash = crypto.createHash('sha1').update(check, 'utf8').digest('hex')
    res.end query.echostr if hash == query.signature

app.post "/talk/webchat", (req, res) ->
        console.log "request from weixin ? " + checkToken(req)
        data = ""
        #res.setEncoding("utf8")
        req.on "data", (chunk) ->
            data += chunk

        req.on "end", () ->
            console.log "receive from weixin: " + data
            parseString data, {explicitArray: false, explicitRoot: false}, (err, result) ->
                #receive ToUserName(dev)/FromUserName(user)/CreateTime/MsgType/Content/MsgId
                #send ToUserName(user)/FromUserName(dev)/CreateTime/MsgType/Content/FuncFlag?

                dev = result.ToUserName
                user = result.FromUserName
                time = result.CreateTime
                type = result.MsgType
                query = result.Content

                talk 3, query , (result) ->
                    console.log "ask: " + query + " type: " + type + " result: " + result
                    res.setHeader('Content-type', 'text/xml; charset=utf8')
                    res.end "<xml>
                        <ToUserName><![CDATA[#{user}]]></ToUserName>
                        <FromUserName><![CDATA[#{dev}]]></FromUserName>
                        <CreateTime>#{time}</CreateTime>
                        <MsgType><![CDATA[text]]></MsgType>
                        <Content><![CDATA[#{result}]]></Content>
                        <FuncFlag>0</FuncFlag>
                    </xml>"
                    
talk = (n, query, callback) ->
    if n == 0
       callback random(no_result)

    console.dir query
    console.log "ask: " + query + " times:" + (3-n)
    if(query == 'Hello2BizUser')
        callback hello
        return

    req = httpsync.get
        url : "http://www.simsimi.com/func/req?msg=#{encodeURIComponent(query)}&lc=ch"
        headers :
            'Referer' : 'http://www.simsimi.com/talk.htm'
            'Cookie' : @cookie
    res = req.end()

    result = JSON.parse(res.data)
    console.dir "simsimi replay: " + JSON.stringify(result)

    if result? and JSON.stringify(result) isnt '{}'
        if result.id? and result.id>1
            console.log "has result id:"+result.id
            callback result.response
        else
            console.log "has no result for id:1"
            set_cookie = res.headers['set-cookie'].split(';').shift()
            console.log "cookie expire, set_cookie: #{set_cookie}"
            @cookie = set_cookie
            talk n-1, query, callback
    else
        console.log "has no result because return empty "
        callback random(no_result)

random = (items) ->
    select = items[ Math.floor(Math.random() * items.length) ]
    console.log "select random :" + select
    return select

app.listen process.env.PORT || 3080
