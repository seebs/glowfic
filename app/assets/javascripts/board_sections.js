$(document).ready( function() {
  $(".section-up").click(function() {
    var old_order = parseInt($(this).attr('data-order'));
    var new_order = old_order - 1;
    if (old_order == 0) { return false; }
    switchRows(old_order, new_order);
    return false;
  });

  $(".section-down").click(function() {
    var old_order = parseInt($(this).attr('data-order'));
    var new_order = old_order + 1;
    if (document.getElementById("section-"+new_order) == null) { console.log("blah"); return false; }
    switchRows(old_order, new_order);
    return false;
  });
});

function switchRows(old_order, new_order) {
  var this_row = $("#section-"+old_order);
  var that_row = $("#section-"+new_order);
  $("#section-"+old_order+" img").attr('data-order', new_order);
  $("#section-"+new_order+" img").attr('data-order', old_order);
  this_row.attr('id', "section-"+new_order);
  that_row.attr('id', "section-"+old_order);

  if(old_order > new_order) {
    this_row.insertBefore(that_row);
  } else {
    this_row.insertAfter(that_row);
  }
  $("#section-table tr:odd td").removeClass('even').addClass("odd");
  $("#section-table tr:even td").removeClass('odd').addClass("even");

  var json = {changes: {}};
  json['changes'][this_row.attr('data-section')] = new_order;
  json['changes'][that_row.attr('data-section')] = old_order;
  json['commit'] = 'reorder';
  $.post(gon.ajax_path, json, function (resp) {
    $("#saveconf").fadeIn().delay(3000).fadeOut();
  });
};
