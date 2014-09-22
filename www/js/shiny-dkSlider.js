var dkSliderInputBinding = new Shiny.InputBinding();

$.extend(dkSliderInputBinding, {
  
  find: function(scope) {
    return $(scope).find('.dkSlider');
  },
  
  getValue: function(el) {
    
    var data_encoded = $(el).uislider("values");
    console.log(data_encoded);
    return data_encoded;
    
    return JSON.stringify(data_encoded);
  },
  
  setValue: function(el, value) {
    console.log("setvalue", value);
    $(el).uislider("values", value);
  },
  
  subscribe: function(el, callback) {
    $(el).on('slidechange.dkSlider', function(e) { callback(); console.log("change");});
  },
  
  unsubscribe: function(el) {
    $(el).off('.dkSlider');
  },
  
  receiveMessage: function(el, data) {
    console.log("message", data);
    if (data.hasOwnProperty('values'))
      this.setValue(el, data.values);
    
    $(el).trigger('change');
  }
});

Shiny.inputBindings.register(dkSliderInputBinding);

function getSliderColors(values) {
  var colors = ["#ff0000", "#00ff00", "#0000ff", "#00ffff"];
  var colorstops = colors[0] + ", "; // start left with the first color
  for (var i=0; i< values.length; i++) {
    colorstops += colors[i] + " " + values[i] + "%,";
    colorstops += colors[i+1] + " " + values[i] + "%,";
  }
  // end with the last color to the right
  colorstops += colors[colors.length-1];
      
  /* Safari 5.1, Chrome 10+ */
  var css = '-webkit-linear-gradient(left,' + colorstops + ')';
  //$(evt.target).css('background-image', css);
  return css;
}