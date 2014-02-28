var Card, CardList,
  meal = require('./scripts/meal');
  _this = this;

this.Card = Card = (function() {
  function Card(parent, card, pass) {
    var tmpl,
      _this = this;
    this.parent = parent;
    this.card = card;
    this.pass = pass;
    tmpl = _.template($('#tmpl-line').html());
    this.$el = $(tmpl({
      card: this.card,
      pass: this.pass
    }))[0];
    $('span.message', this.$el).click(function() {
      $('.control', _this.$el).toggleClass('show');
      return false;
    });
    $('.control', this.$el).mouseout(function() {
      return $(this).removeClass('show');
    });
    $('.button.icon-remove', this.$el).click(function() {
      _this.remove();
      return false;
    });
    $('input', this.$el).keydown(function(e) {
      if (e.keyCode === 13) {
        return _this.go();
      }
    });
    $(this.$el).hide();
    this.parent.prepend(this.$el);
    $(this.$el).show(300, function() {
      if (!(_this.card || _this.pass)) {
        return $('.input-card', _this.$el).focus();
      }
    });
  }

  Card.prototype.addMessage = function(icon, message, style, show) {
    var $control, $icon, $message, $wrap;
    if (style == null) {
      style = '';
    }
    if (style instanceof Array) {
      style = style.join(' ');
    }
    if (typeof style === 'string') {
      style = "message " + style;
    }
    $wrap = $('span.message', this.$el).removeAttr('class').addClass(style).html('');
    $control = $('.control', this.$el);
    if (!(icon && message)) {
      return $control.removeClass('slide');
    }
    $icon = $("<icon class=\"icon-" + icon + "\">");
    $message = $("<span>").text(message);
    $control.addClass('slide');
    $wrap.append($icon).append($message);
    if (show) {
      return $('.control', this.$el).addClass('show');
    }
  };

  Card.prototype.getCard = function() {
    var _ref;
    return (_ref = this.card) != null ? _ref : $('.input-card', this.$el).val();
  };

  Card.prototype.getPass = function() {
    var _ref;
    return (_ref = this.pass) != null ? _ref : $('.input-pass', this.$el).val();
  };

  Card.prototype.remove = function() {
    var _this = this;
    if (this.parent.length() <= 1) {
      return;
    }
    this.parent.remove(this);
    return $(this.$el).hide(300, function() {
      return _this.$el.remove();
    });
  };

  Card.prototype.go = function() {
    var card, pass,
      _this = this;
    card = this.getCard();
    pass = this.getPass();
    if (!(card && pass)) {
      return;
    }
    this.addMessage('loading icon-spin', 'Working');
    return meal({
      card: card,
      pass: pass
    }, function(data) {
      console.log(data);
      if (data.status === 'success') {
        _this.addMessage('tick', 'Done', 'success');
      }
      if (data.status === 'error') {
        return _this.addMessage('cross', data.message, 'fail', true);
      }
    });
  };

  return Card;

})();

this.CardList = CardList = (function() {
  function CardList($el) {
    this.$el = $el;
    this.list = new Array();
  }

  CardList.prototype.add = function(num, pass) {
    return this.list.push(new Card(this, num, pass));
  };

  CardList.prototype.append = function(el) {
    return this.$el.append(el);
  };

  CardList.prototype.prepend = function(el) {
    return this.$el.prepend(el);
  };

  CardList.prototype.start = function() {
    var item, _i, _len, _ref, _results;
    _ref = this.list;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      _results.push(item.go());
    }
    return _results;
  };

  CardList.prototype.length = function() {
    return this.list.length;
  };

  CardList.prototype.indexOf = function(card) {
    return this.list.indexOf(card);
  };

  CardList.prototype.remove = function(index) {
    if (typeof index === 'object') {
      index = this.indexOf(index);
    }
    if (index >= 0) {
      return this.list.splice(index, 1);
    }
  };

  return CardList;

})();

$(document).ready(function() {
  _this.cardList = new CardList($('#card-list'));
  cardList.add();
  $('.button.add').click(function() {
    cardList.add();
    return false;
  });
  $('.button.start').click(function() {
    cardList.start();
    return false;
  });
  if(require) {
    var ngui = require('nw.gui');
    var nwin = ngui.Window.get();
    nwin.show();
  }
});
