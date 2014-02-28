var URIs, async, base, done, errs, fields, headers, i, iconv, j, o, request, stringify, _i, _j, _len, _ref;

async = require('async');

iconv = require('iconv-lite');

request = require('request');

stringify = require('querystring').stringify;

base = 'http://bgy.gd.cn/mis/info/';

URIs = {
  cookies: "" + base + "menu_info.asp?type=%D1%A7%C9%FA%CD%F8%D2%B3",
  login: "" + base + "list.asp",
  booking: "" + base + "dc_info/dc3_new.asp"
};

errs = [];

o = function(msg, str) {
  return errs.push({
    code: errs.length,
    msg: msg,
    str: str
  });
};

o('Cookie Expired', '网页过期!!');

o('Invalid Card Number', '无条形码!!');

o('Wrong Number', '此条形码没有权限!!');

o('Wrong Password', '密码或条形码错误!!');

o('No Available Weeks');

fields = {};

for (i = _i = 1; _i <= 5; i = ++_i) {
  _ref = 'bc'.split('');
  for (_j = 0, _len = _ref.length; _j < _len; _j++) {
    j = _ref[_j];
    fields["D" + i + j] = '11';
    fields["D" + i + j + "j"] = 'A';
  }
}

headers = {
  'content-type': 'application/x-www-form-urlencoded'
};

done = function(err) {
  var ret;
  ret = {
    status: err && 'error' || 'success'
  };
  if (err) {
    ret.code = err.code;
    ret.message = err.msg;
  }
  return ret;
};

module.exports = function(req, res) {
  return async.waterfall(require('nwglobal').Array(
    function(callback) {
      var cookies;
      cookies = request.jar();
      return request(URIs.cookies, {
        jar: cookies
      }, function(err, response, body) {
        return callback(null, cookies);
      });
    }, function(cookies, callback) {
      var body;
      body = {
        tbarno: req.card,
        passwd: req.pass,
        hd: '002',
        B1: '\xc8\xb7\xb6\xa8'
      };
      return request.post(URIs.login, {
        headers: headers,
        body: stringify(body),
        encoding: null,
        jar: cookies
      }, function(err, response, body) {
        var decoded_body, e, _k, _len1;
        decoded_body = iconv.decode(body, 'gbk');
        for (_k = 0, _len1 = errs.length; _k < _len1; _k++) {
          e = errs[_k];
          if (e.str && decoded_body.indexOf(e.str) >= 0) {
            return res(done(e));
          }
        }
        return callback(null, cookies);
      });
    }, function(cookies, callback) {
      return request(URIs.booking, {
        jar: cookies,
        encoding: null
      }, function(err, response, body) {
        var week_list;
        week_list = body.toString().match(/20\d{7}/g).filter(function(v, i, s) {
          return s.indexOf(v) === i;
        });
        if (!week_list.length) {
          return res(done(errs[3]));
        }
        return callback(null, cookies, week_list);
      });
    }, function(cookies, week_list, callback) {
      var body, k, v, w, _k, _len1, _results;
      body = {
        hd: '001',
        size: 'A',
        B1: '\xb1\xa3\xb4\xe6'
      };
      for (k in fields) {
        v = fields[k];
        body[k] = v;
      }
      _results = [];
      for (_k = 0, _len1 = week_list.length; _k < _len1; _k++) {
        w = week_list[_k];
        body.m_date = w;
        _results.push(request.post(URIs.booking, {
          headers: headers,
          body: stringify(body),
          jar: cookies,
          encoding: null
        }, function(err, response, body) {
          return res(done(null));
        }));
      }
      return _results;
    }
  ));
};