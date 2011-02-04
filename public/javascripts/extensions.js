var StringManipulation = {
  changeTextWithNumberBy: function(string, change, pad) {
    if(string && string.match(/\d+$/)) {
      var number = parseInt(string.match(/\d+$/).first(), 10);

      return string.replace(/\d+$/, (number + change).toPaddedString(pad || 0));
    } else {
      return string;
    }
  }
}

Number.prototype.rnd = function() {
  return Math.floor(Math.random() * this + 1)
}

String.prototype.next = function(pad) {
  return StringManipulation.changeTextWithNumberBy(this, 1, pad);
}

String.prototype.previous = function(pad) {
  return StringManipulation.changeTextWithNumberBy(this, -1, pad);
}