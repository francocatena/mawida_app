// Mantiene el estado de la aplicación
var State = {
  // Hash con el contenido del menú
  menu: {},
  // Contador para generar un ID único
  newIdCounter: 0,
  // Registra la variación en el contenido de los formularios
  unsavedData: false,
  // Texto con la advertencia de que hay datos sin guardar
  unsavedDataWarning: undefined,
  // Variable con los mensajes que se deben mostrar diferidos
  showMessages: [],
  // Variable para indicar si la sesión ha expirado
  sessionExpire: false,
  // Mensaje de error para mostrar cuando falla la validación en línea
  validationFailedMessage: undefined
}

// Utilidades para manipular algunos comportamientos del navegador
var BrowserManipulation = {
  /**
     * Carga la nueva URL con los parámetros indicados (debe ser un Hash)
     */
  changeLocation: function(baseUrl, parameters) {
    var params = Util.merge(jQuery.url(undefined, true).param(), parameters);

    Helper.showLoading();
    var query = [];
    
    for(var param in params) {
      var arg = [encodeURIComponent(param)];
      
      if(params[param]) {arg.push(encodeURIComponent(params[param]));}
      
      query.push(arg.join('='))
    }

    window.location = baseUrl + '?' + query.join('&');
  }
}

// Manejadores de eventos
var EventHandler = {

  /**
     * Agrega un ítem anidado
     */
  addNestedItem: function(e) {
    var template = eval(e.data('template'));

    $(e.data('container')).append(Util.replaceIds(template, /NEW_RECORD/g));
  },

  /**
     * Agrega un subitem dentro de un ítem
     */
  addNestedSubitem: function(e) {
    var parent = '.' + e.data('parent') + ':first';
    var child = '.' + e.data('child') + ':first';
    var childContainer = e.parents(parent).find(child);
    var parentObjectId = e.parents(parent).mw('downForIdFromName');
    var template = eval(e.data('template'));

    template = template.replace(/(attributes[_\]\[]+)\d+/g, '$1' +
      parentObjectId);

    childContainer.append(Util.replaceIds(template, /NEW_SUBRECORD/g));
  },

  /**
     * Oculta un elemento (agregado con alguna de las funciones para agregado
     * dinámico)
     */
  hideItem: function(e) {
    var target = e.data('target');
    
    Helper.hideItem(e.parents(target));

    e.prev('input[type=hidden].destroy').val('1');
    
    e.parents(target).find('input.sort_number').addClass('hidden_sort_number').
      removeClass('sort_number');

    FormUtil.completeSortNumbers();
    
    e.trigger('item:removed');
  },

  /**
     * Simula el comportamiento del botón "Atrás"
     */
  historyBack: function() {
    if(window.history.length > 0) {window.history.back(1);}
  },

  /**
     * Inserta un elemento al final del contenedor
     */
  insertRecordItem: function(e) {
    var template = eval(e.data('template'));

    e.parents(e.data('target')).before(Util.replaceIds(template, /NEW_RECORD/g));
  },

  /**
     * Inserta un subelemento al final del contenedor
     */
  insertRecordSubitem: function(e) {
    var target = e.data('target');
    var parent = '.' + e.data('parent') + ':first';
    var parentObjectId = e.parents(parent).mw('downForIdFromName');
    var template = eval(e.data('template'));

    template = template.replace(/(attributes[_\]\[]+)\d+/g, '$1' +
      parentObjectId);

    e.parents(target).before(Util.replaceIds(template, /NEW_SUBRECORD/g));
  },
  
  /**
   * Marca un archivo adjunto para ser eliminado
   */
  removeAttachment: function(e) {
    e.prevAll('input[type=hidden].destroy').val('1');
    e.prevAll('a.image_link').fadeOut();
    e.fadeOut();
  },

  /**
     * Elimina el elemento del DOM
     */
  removeItem: function(e) {
    Helper.removeItem(e.parents(e.data('target')), function() {
      FormUtil.completeSortNumbers();
    });
    
    e.trigger('item:removed');
  },

  /**
     * Elimina el elemento del DOM
     */
  removeListItem: function(e) {
    Helper.removeItem(e.parents('.item'));
  }
}

// Utilidades para formularios
var FormUtil = {
  /**
     * Completa todos los inputs con la clase "sort_number" con números en secuencia
     */
  completeSortNumbers: function() {
    $('input.sort_number').val(function(i) {return i + 1;});
  }
}

// Utilidades varias para asistir con efectos sobre los elementos
var Helper = {
  /**
     * Oculta el elemento indicado
     */
  hideItem: function(element, callback) {
    var func = $(element).is('tr') ? 'fadeOut' : 'slideUp';
    var time = $(element).is('tr') ? 300 : 500;
    
    $(element).stop()[func](time, callback);
  },

  /**
     * Oculta el elemento que indica que algo se está cargando
     */
  hideLoading: function(element) {
    $('#loading:visible').hide();

    $(element).removeAttr('disabled');
  },

  /**
     * Convierte en "ordenable" (utilizando drag & drop) a un componente
     */
  makeSortable: function(elementId, elements, handles) {
    $(elementId).sortable({
      axis: 'y',
      items: elements,
      handle: handles,
      opacity: 0.6,
      stop: function() { FormUtil.completeSortNumbers(); }
    });
    
    // Queridisimo Explorer
    if($.browser.msie) { $(elementId).find(elements).css('opacity', '1'); }
  },

  /**
     * Elimina el elemento indicado
     */
  removeItem: function(element, callback) {
    var func = $(element).is('tr') ? 'fadeOut' : 'slideUp';
    var time = $(element).is('tr') ? 300 : 500;
    
    $(element).stop()[func](time, function() {
      $(element).remove();
      
      if(jQuery.isFunction(callback)) {callback();}
    });
  },

  /**
     * Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
     */
  showItem: function(element, callback) {
    var e = $(element);

    if(e.is(':not(:visible):not(:animated)')) {
      var func = $(element).is('tr') ? 'fadeIn' : 'slideDown';
      var time = $(element).is('tr') ? 300 : 500;
      
      e[func](time, function() {
        e.find(
          '*[autofocus]:not([readonly]):not([disabled]):visible:first'
        ).focus();

        if(jQuery.isFunction(callback)) {callback();}
      });
    }
  },

  /**
     * Muestra el último ítem que cumple con la regla de CSS
     */
  showLastItem: function(cssRule) {
    Helper.showItem($(cssRule + ':last'));
  },

  /**
     * Muestra una imagen para indicar que una operación está en curso
     */
  showLoading: function(element) {
    $('#loading:not(:visible)').show();

    $(element).attr('disabled', true);
  },

  /**
     * Muestra mensajes en el div "time_left" si existe
     */
  showMessage: function(message, expired) {
    $('#time_left').find('span.message').html(message);
    $('#time_left:not(:visible)').stop().fadeIn();

    State.sessionExpire = State.sessionExpire || expired;
  },

  showOrHideWithArrow: function(elementId) {
    Helper.toggleItem('#' + elementId, function() {
      var links = [
        '#show_element_' + elementId + '_content',
        '#hide_element_' + elementId + '_content'
      ];
      
      $(links.join(', ')).toggle();
    });
  },

  /**
     * Intercambia los efectos de desplegar y contraer sobre un elemento
     */
  toggleItem: function(element, callback) {
    $(element).slideToggle(500, callback);
  }
}

// Utilidades para generar y modificar HTML
var HTMLUtil = {
  /**
     * Convierte un array en un elemento UL con los items como elementos LI, si
     * el elemento es a su vez un array se convierte recursivamente en un UL
     */
  arrayToUL: function(array, attributes) {
    if($.isArray(array) && array.length > 0) {
      var ul = $('<ul></ul>', attributes);
      
      $.each(array, function(i, e) {
        if($.isArray(e) && e.length > 1 && typeof e[0] == 'string' &&
          $.isArray(e[1])) {
          var li = $('<li></li>');

          li.append(e.shift());
          li.append(HTMLUtil.arrayToUL(e, {}));

          ul.append(li);
        } else {
          if($.isArray(e)) {
            $.each(e, function(i, se) {ul.append($('<li></li>').html(se));});
          } else {
            ul.append($('<li></li>').html(e));
          }
        }
      });

      return ul;
    } else {
      return '';
    }
  },

  /**
     * Convierte un arreglo de opciones en un string para insertar dentro de
     * etiquetas
     */
  optionsFromArray: function(optionsArray, selectedValue, includeBlank) {
    var options = $.map(optionsArray, function(e) {
      var optionString = selectedValue && e[0] == selectedValue ?
        '<option selected="selected" value=' + e[1] + '>' + e[0] + '</option>' :
        '<option value=' + e[1] + '>' + e[0] + '</option>'

      return optionString;
    }).join(' ');

    return includeBlank ? '<option value=""></option>' + options : options;
  },
  
  /**
     * Ejecuta la función HTMLUtil.stylizeInputFile en todos los inputs de tipo file dentro
     * de un contenedor span con clase file_container
     */
  stylizeAllInputFiles: function() {
    $('span.file_container').each(function(i, e) {
      HTMLUtil.stylizeInputFile($(e));
      Observer.attachToInputFile($(e));
    });
  },

  /**
     * Aplica un estilo "falso" a los inputs de tipo file
     */
  stylizeInputFile: function(element) {
    if (!element || element.length == 0) return;

    var input = $(element).find('input[type=file]');

    if(input.parents('div.stylized_file').length == 0) {
      element.mousemove(function(event) {
        var left = (event.pageX - $(this).offset().left) - input.width() + 10;
        var container = input.parents('span.file_container');
        var xMin = container.position().left + container.width();
        var xMax = xMin + container.width();

        // Esta pregunta es por un bug en IE7 con overflow: hidden
        if(event.pageX >= xMin && event.pageX <= xMax) {
          input.css({left: left + 'px'});
        }
      });
      
      element.wrap('<div class="stylized_file"></div>');
    }
  },

  /**
     * Actualiza as opciones del select indicado y lo habilita si tiene por lo
     * menos una opción
     */
  updateOptions: function(selectElement, optionsString) {
    var element = $(selectElement);

    element.html(optionsString).attr(
      'disabled', $('option', element).length == 0
    );
  }
}

// Manipulación del menú
var Menu = {
  /**
     * Muestra el menú principal
     */
  show: function() {
    $('#app_content').hide();
    
    if($('#main_mobile_menu').length > 0) {
      $('#session').show();
      $('#main_mobile_menu').show();
    } else {
      $('#app_content').after(
        $('#main_menu').clone().attr('id', 'main_mobile_menu')
      );
      $('#main_mobile_menu').before($('#session'))
    }
    
    $('#show_menu').hide();
    $('#hide_menu').show();
  },
  
  hide: function() {
    $('#main_mobile_menu').hide();
    $('#session').hide();
    $('#app_content').show();
    $('#hide_menu').hide();
    $('#show_menu').show();
  }
}

// Observadores de eventos
var Observer = {
  /**
     * Agrega un listener a los eventos de click en el menú principal
     */
  attachToMenu: function() {
    $(document).on('click', '#menu_container a', function(event) {
      var menuName = $(this).attr('href').replace(/.*#/, '')
      var content = State.menu[menuName];
      
      if($(this).hasClass('menu_item_1') && content) {
        $('#menu_level_1').html(content);
        $('#menu_level_2').html('&nbsp;');
        $('.menu_item_1').removeClass('highlight');
        
        event.stopPropagation();
        event.preventDefault();
      } else if($(this).hasClass('menu_item_2') && content) {
        $('#menu_level_2').html(content);
        $('.menu_item_2').removeClass('highlight');
        
        event.stopPropagation();
        event.preventDefault();
      }
      
      $(this).addClass('highlight');
    });
  },
  /**
     * Agrega un listener a los eventos de click en el menú principal en móviles
     */
  attachToMobileMenu: function() {
    $(document).on('click', '#main_container a', function(event) {
      var e = $(this);
      var menuName = e.attr('href').replace(/.*#/, '');
      var content = State.menu[menuName];

      if(e.is('.menu_item_1, .menu_item_2') && content) {
        $('#main_mobile_menu').data(
          'previous-' + e.parents('ul').data('level'),
          $('#main_mobile_menu').html()
        );
        
        $('#main_mobile_menu').html(content);

        event.stopPropagation();
        event.preventDefault();
      } else if(e.is('.back')) {
        $('#main_mobile_menu').html(
          $('#main_mobile_menu').data(
            'previous-' + (e.parents('ul').data('level') - 1)
          )
        );
      }
    });
  },
  
  attachToInputFile: function(span) {
    span.find('input[type=file]:not(data-observed)').one('change', function() {
      var e = $(this);

      if(e.hasClass('file') && !e.val().match(/^\s*$/)) {
        var imageTag = $('<img />', {
          src: '/assets/new_document.gif',
          width: 22,
          height: 20,
          alt: e.val(),
          title: e.val()
        });
        
        e.parents('span.file_container:visible').hide().after(imageTag);
      }
    });
  }
}

// Funciones relacionadas con la búsqueda
var Search = {
  observe: function() {
    $('#column_headers th.filterable').click(function() {
      var e = $(this);
      var columns = e.find('input[type="hidden"]').map(function() {
        return $(this).val();
      }).get();
      var hiddenFilter = $.map(columns, function(e) {
        return 'input[value="' + e + '"]';
      }).join(', ');
      
      var columnNamesDiv = $('#search_column_names');

      if(e.hasClass('selected')) {
        e.addClass('disabled').removeClass('selected');

        columnNamesDiv.find(hiddenFilter).remove();
      } else {
        $.each(columns, function(i, e) {
          var hiddenColumn = $('<input />', {
            'type': 'hidden',
            'name': 'search[columns][]'
          }).val(e);

          columnNamesDiv.append(hiddenColumn);
        });

        e.addClass('selected').removeClass('disabled');
      }

      $('#search_query').focus();
    });
  },
  
  show: function() {
    var search = $('#search:not(:visible):not(:animated)');

    if(search.length > 0) {
      var headers = $('th', $('#column_headers'));

      headers.each(function() {
        if($(this).hasClass('filterable')) {
          $(this).addClass('selected');
        } else {
          $(this).addClass('not_available');
        }
      });

      if($('#filter_box').length > 0) {
        $('#filter_box').hide();
        $(search).fadeIn(300, function() {$('#search_query').focus();});
      } else {
        search.fadeIn(300, function() {$('#search_query').focus();});
      }

      $('#show_search_link').hide();

      Search.observe();
    } else {
      $('#search_query').focus();
    }
  }
}

// Utilidades varias
var Util = {
  /**
     * Combina dos hash javascript nativos
     */
  merge: function(hashOne, hashTwo) {
    return jQuery.extend({}, hashOne, hashTwo);
  },

  /**
     * Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
     * único generado con la fecha y un número incremental
     */
  replaceIds: function(s, regex){
    return s.replace(regex, new Date().getTime() + State.newIdCounter++);
  }
}

// Funciones ejecutadas cuando se carga cada página
jQuery(function($) {
  var eventList = $.map(EventHandler, function(v, k ) {return k;});
  
  // Para que los navegadores que no soportan HTML5 funcionen con autofocus
  $('[autofocus]:not([readonly]):not([disabled]):visible:first').focus();
  
  $(document).bind('ajax:after', function(event) {
    Helper.showLoading($(event.target));
  });
  
  $(document).bind('ajax:complete', function(event) {
    Helper.hideLoading($(event.target));
  });

  $(document).keydown(function(event) {
    if (event.which == 32 && event.ctrlKey) {
      Search.show();
      
      event.stopPropagation();
      event.preventDefault();
    }
  });

  $(document).on('click', 'a[data-event]', function(event) {
    if (event.stopped) return;
    var eventName = $(this).data('event');

    if($.inArray(eventName, eventList) != -1) {
      EventHandler[eventName]($(this));
      
      event.preventDefault();
      event.stopPropagation();
    }
  });
  
  $(document).on('focus', 'input.calendar:not(.hasDatepicker)', function() {
    if($(this).data('time')) {
      $(this).datetimepicker({showOn: 'both'}).focus();
    } else {
      $(this).datepicker({
        showOn: 'both',
        onSelect: function() {$(this).datepicker('hide');}
      }).focus();
    }
  });

  // Cuando se remueve o se oculta un papel de trabajo reutilizar el código
  $(document).on('item:removed', '.work_paper', function() {
    var workPaperCode = $(this).find('input[name$="[code]"]').val();

    if(workPaperCode == lastWorkPaperCode) {
      lastWorkPaperCode = lastWorkPaperCode.previous(2);
    }
  });
  
  $('.popup').dialog({
    autoOpen: false,
    draggable: false,
    resizable: false,
    height: 'auto',
    minHeight: 50,
    maxWidth: 400,
    width: 'auto',
    close: function() {
      $(this).parents('.ui-dialog').show().fadeOut(500);
    },
    open: function(){
      $(this).parents('.ui-dialog').hide().fadeIn(500);
    }
  });
  
  $(document).on('click', 'span.popup_link', function(event) {
    $($(this).data('helpDialog')).dialog('open').dialog(
      'option', 'position', [
        event.pageX - $(window).scrollLeft(),
        event.pageY - $(window).scrollTop()
      ]
    );
    
    return false;
  });

  if($('#menu_container').length > 0 && !/mobi|mini/i.test(navigator.userAgent)) {
    Observer.attachToMenu();
  } else if($('#mobile_menu').length > 0) {
    Observer.attachToMobileMenu();
  }

  // Mensajes diferidos
  if($.isArray(State.showMessages)) {
    $.each(State.showMessages, function() {
      var message = this.message;
      var expired = this.expired;
      
      this.timer_id = window.setTimeout(
        "Helper.showMessage('" + message + "', " + expired + ")",
        this.time * 1000
      );
    });
  }
  
  $(document).bind({
    // Reinicia los timers con los mensajes diferidos
    ajaxStart: function() {
      $.each(State.showMessages, function() {
        if(!State.sessionExpire) {
          window.clearTimeout(this.timer_id);
          $('#time_left').hide();

          var message = this.message;
          var expired = this.expired;

          this.timer_id = window.setTimeout(
            "Helper.showMessage('" + message + "', " + expired + ")",
            this.time * 1000
          );
        }
      });
    }
  });
  
  $('#loading').bind({
    ajaxStart: function() {$(this).show();},
    ajaxStop: function() {$(this).hide();}
  });
  
  AutoComplete.observeAll();
});
