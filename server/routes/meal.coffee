async = require 'async'
iconv = require 'iconv-lite'
request = require 'request'
stringify = require('querystring').stringify

URIs =
  cookies: 'http://bgy.gd.cn/mis/info/menu_info.asp?type=%D1%A7%C9%FA%CD%F8%D2%B3'
  login: 'http://bgy.gd.cn/mis/info/list.asp'
  booking: 'http://bgy.gd.cn/mis/info/dc_info/dc3_new.asp'

errcode = [
  {
    str: '网页过期!!'
    msg: 'Cookie Expired'
    code: '0001'
  }
  {
    str: '无条形码!!'
    msg: 'Please Submit Card Number'
    code: '0002'
  }
  {
    str: '此条形码没有权限!!'
    msg: 'Wrong Number'
    code: '0003'
  }
  {
    str: '密码或条形码错误!!'
    msg: 'Wrong Password'
    code: '0004'
  }
  {
    msg: 'No Available Weeks'
    code: '0005'
  }
]

fields = {}
for i in [1..5]
  for j in 'bc'.split ''
    fields["D#{i}#{j}"] = '11'
    fields["D#{i}#{j}j"] = 'A'

headers =
  'content-type': 'application/x-www-form-urlencoded'

done = (err) ->
  ret =
    status: if err then 'error' else 'success'
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
        for e in errcode
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
          return res.send done errcode[3]
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
