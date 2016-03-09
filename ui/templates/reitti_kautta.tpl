{% extends "base.tpl" %}
{% block title %}Reitit{% endblock %}
{% block content %}
    <div class="col-md-4">
    <h1>Pysäkkien kautta kulkevat vuorot</h1>
    <form role="form" method="post" action="{{ reverse_url('reitit.kautta') }}" id="searchform">
    <div class="form-group">
        <label for="stationInput">Pysäkkihaku</label><br/>
        <input type="text" class="form-control" id="stationInput" name="station" placeholder="Pysäkin nimi tai tunnus"/>
    </div>
    <div class="form-group">
    <table class="table">
    <thead>
        <tr><th>Valitut pysäkit</th></tr>
    </thead>
    <tbody id="pysres">
    </tbody>
    </table>
    </div>
    <input type="submit" class="btn btn-default" value="Hae" name="sbmt"/>
    {{xsrf_form_html()}}
    </form>
    </div>
    <div class="col-md-8">
    <h1>Hakutulokset</h1>
    <table class="table table-striped results">
        <thead>
            <tr>
                <th>Reitin tunnus</th>
                <th>Lupasopimustunnus</th>
                <th>Liikenteenharjoittaja</th>
                <th>Reittinimi</th>
                <th>Vuorotyyppi</th>
                <th>Vuoromäärä</th>
                <th>&nbsp;</th>
            </tr>
        </thead>
        <tbody id="results">
        {% for v in reitit %}
        <tr>
            <td>{{v.reittiid}}</td>
            <td>{{v.lupasoptunnus}}</td>
            <td>{{v.liikharj_nimi}}</td>
            <td>{{v.reittinimi}}</td>
            <td>{{v.vuorotyyppi}}</td>
            <td>{{v.vuoromaara}}</td>
            <td>{{v.vuoron_url_interpoloitu}}</td>
        </tr>
        {% endfor %}
        </tbody>
    </table>
    <button id="csvoutbtn" class="btn btn-primary">Vie CSV</button>
    </div>


<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="nearlabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
        <h4 class="modal-title" id="nearlabel">Lisää pysäkit läheltä</h4>
      </div>
      <div class="modal-body">
        <label for="neardist">Etäisyys:</label><input type="text" id="nardist" name="neardist"/> metriä
        <button type="button" class="btn btn-primary" id="nearsearch">Hae pysäkit</button>
        <table class="table">
            <thead>
                <tr>
                    <th>Nimi</th><th>Tunnus</th><th>Etäisyys</th><th>&nbsp;</th>
            </thead>
            <tbody id="nearlist">
            </tbody>
        </table>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal" id="nearclose">Sulje</button>
        <button type="button" class="btn btn-primary" id="nearadds">Lisää valitut pysäkit</button>
      </div>
    </div>
  </div>
</div>

{% endblock %}

{%block style %}
.results td,
.results th {
    font-size: 11px;
}
{% endblock %}
<script>
{% block script %}
var selected_station = null;
$(function() {
  var getSelectedStations = function() {
      var selstations = [];
      $('tr:data(stationId)').map(function(k, v) {
          selstations.push($(v).data('stationId'));
      });

      return selstations;
  }

  $('#csvoutbtn').click(function(e) {
      var selstations = getSelectedStations();
      var frm = $('<form method="post" action="{{reverse_url('reitit.kautta')}}?format=csv">');
      frm.append($('<input type="hidden" name="stations"/>').val(selstations.join(',')));
      frm.append($('<input type="hidden" name="_xsrf"/>').val(getCookie("_xsrf")));
      var sbtn = '<input type="submit" name="s"/>';
      frm.append(sbtn);
      $('body').append(frm);
      frm.submit();
      return false;
  });

    $('#searchform').submit(function() {
        var selstations = getSelectedStations();

        $.post('/joukkoliikenne/katselu/reitit/kautta?format=json', {
            stations: selstations.join(','),
            "_xsrf": getCookie("_xsrf")
        }, function(d) {
            $('#results').html('');
            d.forEach(function(v) {
                $('#results').append('<tr>' +
                    '<td><a href="/joukkoliikenne/katselu/reitti/' + v.reittiid + '">' + v.reittiid + '</a></td>' +
                    '<td><a href="#' + v.lupasoptunnus + '">' + v.lupasoptunnus + '</a></td>' +
                    '<td><a href="#' + v.liikharjnro + '">' + v.liikharj_nimi + '</a></td>' +
                    '<td><a href="/joukkoliikenne/katselu/reitti/' + v.reittiid + '">' + v.reittinimi + '</a></td>' +
                    '<td>' + v.vuorotyyppi + '</td>' +
                    '<td>' + v.vuoromaara + '</td>' +
                    '<td><a href="' + v.vuoron_url_interpoloitu + '">Katselu</a></td>' +
                    '</tr>')
            });
        }, 'json');

        return false;
    });


    var stations = new Bloodhound({
        datumTokenizer: function(datum) {
            return Bloodhound.tokenizers.whitespace(datum.value);
        },
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
            url: '/joukkoliikenne/katselu/pysakit?q=%QUERY&format=json',
            filter: function(stations) {
                return stations.map(function(s) {
                    return $.extend({},s,{
                        name: s.nimi,
                        value: s.gid.toString()
                    });
                }, stations);
            }
        },
        limit:10
    });

    // Initialize the Bloodhound suggestion engine
    stations.initialize();

    // Instantiate the Typeahead UI
    $('#stationInput').typeahead(null, {
        templates: {
            suggestion: function (b) {
                return '<p><strong>' + b.nimi + '</strong> (' + b.valtakid + ')</p>';
            }
        },
        source: stations.ttAdapter()
    });


    var addStationToSelected = function (b) {
        var stationid = b.gid.toString();
        var dupl = false;
        $('tr:data(stationId)').map(function(k, v) {
            if ($(v).data('stationId') == stationid) {
                dupl = true;
                return false;
            }
        });

        if (dupl) {
            return false;
        }
        $('#stationInput').typeahead('val', '');

        var stationrow = $('<tr>').data('stationId', stationid);
        var cell = $('<td><strong>' + b.nimi + '</strong> (' + b.valtakid + ')</td>');
        var nearbtn = $('<button class="btn btn-xs" data-toggle="modal" data-target="#myModal">Lisää pysäkit läheltä</button>');
        nearbtn = nearbtn.data('stationId', stationid);
        nearbtn.click(function(e) {
            selected_station = $(e.currentTarget).data('stationId');
            return true;
        });

        cell = cell.append('<br/>');
        cell = cell.append(nearbtn);

        cell = cell.append('&nbsp;');
        cell = cell.append($('<button class="btn btn-primary btn-xs">Poista valinta</button>').click(function(e) {
            $(e.currentTarget.parentNode.parentNode).remove();
            return false;
        }));
        $('#pysres').append(stationrow.append(cell));

    }
    $('#stationInput').bind('typeahead:selected', function(a, b, c) {
        addStationToSelected(b);
    });

    $('#nearsearch').click(function (e) {
        $('#nearlist').html('');
        //console.log('laheiset',selected_station,'etäisyys',$('#nardist').val(),'metriä');
        $.getJSON('/joukkoliikenne/katselu/pysakit/lahella?format=json&s=' + selected_station + '&d=' + parseInt($('#nardist').val()),function (d) {
            d.forEach(function (s) {
                var inp = $('<input type="checkbox" checked="checked" ref="' + s.gid + '" class="selstation"/>').data('station',s);
                $('#nearlist').append(
                    $('<tr>')
                    .append('<td>' + s.nimi + '</td>').append('<td>' + s.gid + '</td>').append('<td>' + (Math.round(Math.sqrt(s.dist)*10)/10) + ' m</td>')
                    .append($('<td>').append(inp)));
            })
        });
    });

    $('#nearadds').click(function (e) {
        $('.selstation').each(function (k,v) {
            addStationToSelected($(v).data('station'));
        });

        $('#nearlist').html('');
        $('#nearclose').click();
    });

});
{% endblock %}
</script>
