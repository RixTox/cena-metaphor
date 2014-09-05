async       = require 'async'
iconv       = require 'iconv-lite'
request     = require 'request'
{stringify} = require 'querystring'

base = 'http://bgy.gd.cn:8080/mis/info/'

URIs =
  cookies: "#{base}menu_info.asp?type=%D1%A7%C9%FA%CD%F8%D2%B3"
  login:   "#{base}list.asp"
  booking: "#{base}dc_info/dc3_new.asp"

errs = []
o = (msg, str) ->
  errs.push {code:errs.length,msg,str}

o 'Cookie Expired'      , '网页过期!!'
o 'Invalid Card Number' , '无条形码!!'
o 'Wrong Number'        , '此条形码没有权限!!'
o 'Wrong Password'      , '密码或条形码错误!!'
o 'No Available Weeks'

fields = {}
for i in [1..5]
  for j in 'bc'.split ''
    fields["D#{i}#{j}"] = '11'
    fields["D#{i}#{j}j"] = 'A'

headers =
  'content-type': 'application/x-www-form-urlencoded'

done = (err) ->
  ret =
    status: err && 'error' || 'success'
  if err
    ret.code = err.code
    ret.message = err.msg
  return ret

module.exports = (req, res) ->
  async.waterfall [

    # get cookies
    (callback) ->
      cookies = request.jar()
      request URIs.cookies,
        jar: cookies
      , (err, response, body) ->
        callback null, cookies

    # perform login
    (cookies, callback) ->
      body =
        tbarno: req.param 'card'
        passwd: req.param 'pass'
        hd: '002'
        B1: '\xc8\xb7\xb6\xa8'
      request.post URIs.login,
        headers: headers
        body: stringify body
        encoding: null
        jar: cookies
      , (err, response, body) ->
        decoded_body = iconv.decode body, 'gbk'
        for e in errs
          if e.str and decoded_body.indexOf(e.str) >= 0
            return res.send done e
        callback null, cookies

    # get week list
    (cookies, callback) ->
      request URIs.booking,
        jar: cookies
        encoding: null
      , (err, response, body) ->
        week_list = body
          .toString()
          .match(/20\d{7}/g)
          .filter (v,i,s) ->
            s.indexOf(v) == i
        unless week_list.length
          return res.send done errs[3]
        callback null, cookies, week_list

    # book meal
    (cookies, week_list, callback) ->
      body =
        hd: '001'
        size: 'A'
        B1: '\xb1\xa3\xb4\xe6'
      for k, v of fields
        body[k] = v
      for w in week_list
        body.m_date = w
        request.post URIs.booking,
          headers: headers
          body: stringify body
          jar: cookies
          encoding: null
        , (err, response, body) ->
          res.send done null
  ]
