{% extends "base.tpl" %}

{% macro groupseltable(groupname) -%}
<table class="table table-condensed">
    <thead>
        <tr>
            <th>Pysäkki</th>
            <th>Vk. tunnus</th>
            <th>Kunta</th>
            <th>&nbsp;</th>
        </tr>
    </thead>
    <tbody id="selpys{{groupname}}" class="selpys">
        <tr class="empty">
            <td colspan="4">Ei valittuja pysäkkejä tässä ryhmässä</td>
        </tr>
    </tbody>
    <tfoot>
        <tr>
            <td colspan="4"><button class="btn btn-sm btn-warning emptysel">Tyhjennä lista</button></td>
        </tr>
    </tfoot>
</table>
{%- endmacro %}

{% block title %}Reitit{% endblock %}
{% block content %}
<div class="row">
    <div class="col-md-12">
        <h1>Vuorot kahden paikan välillä</h1>
    </div>
</div>
<div class="row">
    <div class="col-md-12">
        <h2><a href="#" id="formhead">Hakuvalinnat</a></h2>
    </div>
</div>
<div class="row" id="formdiv">
    <div class="col-md-3">
        <h3>Pysäkkivalinta</h3>
        <form role="form" method="post" action="{{ reverse_url('reitit.matriisi') }}">
            <div class="form-group">
                <label for="stationInput">Pysäkkihaku</label>
                <br/>
                <input type="text" class="form-control" id="stationInput" name="station" placeholder="Pysäkin nimi tai tunnus" />
            </div>
        </form>
        <table class="table table-condensed">
            <thead>
                <tr>
                    <th colspan="2">Valitut pysäkit</th>
                </tr>
            </thead>
            <tbody id="pysres">
            </tbody>
            <tfoot>
                <tr>
                    <th>Lisää valitut</th>
                    <tr>
                        <td>
                            <button class="btn btn-sm btn-info addtogroupbtn" data-group="a">Ryhmään A</button>&nbsp;
                            <button class="btn btn-sm btn-info addtogroupbtn" data-group="b">Ryhmään B</button>
                        </td>
                    </tr>
            </tfoot>
        </table>
        <h3>Kuntavalinta</h3>
        <form role="form" method="post" action="{{ reverse_url('reitit.matriisi') }}">
            <div class="form-group">
                <input type="text" class="form-control" id="kuntaInput" name="kunta" placeholder="Kunnan nimi" />
            </div>
            <div class="form-group">
                <button class="btn btn-sm btn-info addmuncip" data-group="a">Ryhmään A</button>&nbsp;
                <button class="btn btn-sm btn-info addmuncip" data-group="b">Ryhmään B</button>
            </div>
        </form>
    </div>
    <div class="col-md-9">
        <div class="row">
            <div class="col-md-12">
                <p class="text-right">
                    <button class="btn btn-primary btn-lg searchbtn">Suorita haku</button>
                </p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-6">
                <div class="panel panel-default">
                    <div class="panel-heading"><strong>Pysäkkiryhmä A</strong>
                    </div>
                    <div class="panel-body">
                        {{groupseltable('a')}}
                    </div>
                </div>

            </div>
            <div class="col-md-6">
                <div class="panel panel-default">
                    <div class="panel-heading"><strong>Pysäkkiryhmä B</strong>
                    </div>
                    <div class="panel-body">
                        {{groupseltable('b')}}
                    </div>
                </div>

            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <p class="text-right">
                    <button class="btn btn-primary btn-lg searchbtn">Suorita haku</button>
                </p>
            </div>
        </div>
    </div>
</div>
<div class="row">
    <div class="col-md-12">
        <h2>Tulokset</h2>
    </div>
</div>
<div class="row" id="resultsdiv">
    <div class="col-md-12">
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
                <td>{{v.vuoron_url_interpoloitu}}</td>
            </tr>
            {% endfor %}
            </tbody>
        </table>
        <button id="csvoutbtn" class="btn btn-primary">Vie CSV</button>
    </div>
</div>

<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="nearlabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span>
                </button>
                <h4 class="modal-title" id="nearlabel">Lisää pysäkit läheltä</h4>
            </div>
            <div class="modal-body">
                <label for="neardist">Etäisyys:</label>
                <input type="text" id="nardist" name="neardist" /> metriä
                <button type="button" class="btn btn-primary" id="nearsearch">Hae pysäkit</button>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Nimi</th>
                            <th>Tunnus</th>
                            <th>Etäisyys</th>
                            <th>&nbsp;</th>
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
#pysres td,
.tt-suggestion {
    font-size: 12px;
}

.selpys td {
    font-size:12px;
}

.results td,
.results th {
    font-size: 11px;
}
{% endblock %}
<script>
{% block script %}
var kuntanumerot = {{kuntanumerot}};
var selected_station = null;
var selected_muncip = null;
var format = 'json';
$(function() {

    $('#resultsdiv').hide();
    // constructs the suggestion engine
    var kunnatb = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        // `states` is an array of state names defined in "The Basics"
        local: function() {
                var kunnat = [];
                for (var kn in kuntanumerot) {
                    kunnat.push({
                        name: kuntanumerot[kn],
                        id: parseInt(kn)
                    });
                }
                return kunnat;
            },
          limit: 10
    });

    // kicks off the loading/processing of `local` and `prefetch`
    kunnatb.initialize();

    $('#kuntaInput').typeahead(null, {
        displayKey: 'name',
        source: kunnatb.ttAdapter()
    });

    $('#kuntaInput').bind('typeahead:selected', function(a, b, c) {
        selected_muncip = b;
    });

    $('.addmuncip').click(function(e) {
        if (selected_muncip == null) return false;

        var groupname = $(e.currentTarget).data('group');
        $('#selpys' + groupname + ' tr.empty').remove();
        var row = $('<tr>').data('muncip', selected_muncip);
        row.append('<td><strong>Kaikki</strong></td>');
        row.append('<td>' + selected_muncip.id + '</td>');
        row.append('<td>' + selected_muncip.name + '</td>');
        var dellink = $('<a href="#" class="removeselpys">Poista</a>');
        dellink.click(function(e) {
            $(e.currentTarget).closest('tr').remove();
            return false;
        });

        row.append($('<td>').append(dellink));

        $('#selpys' + groupname).append(row);
        selected_muncip = null;
        $('#kuntaInput').typeahead('val', '');

        return false;
    });


    var stations = new Bloodhound({
        datumTokenizer: function(datum) {
            return Bloodhound.tokenizers.whitespace(datum.value);
        },
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
            url: '{{reverse_url('pysakit')}}?q=%QUERY&format=json',
            filter: function(stations) {
                return stations.map(function(s) {
                    return $.extend({}, s, {
                        name: s.nimi,
                        value: s.gid.toString()
                    });
                }, stations);
            }
        },
        limit: 10
    });

    // Initialize the Bloodhound suggestion engine
    stations.initialize();

    // Instantiate the Typeahead UI
    $('#stationInput').typeahead(null, {
        templates: {
            suggestion: function(b) {
                return '<p><strong>' + b.nimi + '</strong> (' + b.valtakid + ')</p>';
            }
        },
        source: stations.ttAdapter()
    });


    $('#stationInput').typeahead('val', '');
    $('#kuntaInput').typeahead('val', '');

    var addStationToSelected = function(b) {

        var stationid = b.gid.toString();
        var dupl = false;
        $('#pysres tr:data(station)').map(function(k, v) {
            if ($(v).data('station').stationid == stationid) {
                dupl = true;
                return false;
            }
        });

        if (dupl) {
            return false;
        }
        $('#stationInput').typeahead('val', '');

        var stationrow = $('<tr>').data('station', b);
        var cell = $('<td><strong>' + b.nimi + '</strong> (' + b.valtakid + ')</td>');
        var nearbtn = $('<button class="btn btn-xs" data-toggle="modal" data-target="#myModal">Lisää pysäkit läheltä</button>');
        nearbtn = nearbtn.data('station', b);
        nearbtn.click(function(e) {
            selected_station = $(e.currentTarget).data('station').gid;
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

    $('#nearsearch').click(function(e) {
        $('#nearlist').html('');
        //console.log('laheiset',selected_station,'etäisyys',$('#nardist').val(),'metriä');
        $.getJSON('{{reverse_url('pysakit.lahella')}}?format=json&s=' + selected_station + '&d=' + parseInt($('#nardist').val()), function(d) {
            d.forEach(function(s) {
                var inp = $('<input type="checkbox" checked="checked" ref="' + s.gid + '" class="selstation"/>').data('station', s);
                $('#nearlist').append(
                    $('<tr>')
                    .append('<td>' + s.nimi + '</td>').append('<td>' + s.gid + '</td>').append('<td>' + (Math.round(Math.sqrt(s.dist) * 10) / 10) + ' m</td>')
                    .append($('<td>').append(inp)));
            })
        });
    });

    $('#nearadds').click(function(e) {
        $('.selstation').each(function(k, v) {
            addStationToSelected($(v).data('station'));
        });

        $('#nearlist').html('');
        $('#nearclose').click();
    });

    var addStationToGroup = function(groupname, station) {
        var dupl = false;
        console.log(groupname,station);
        $('#selpys' + groupname + ' tr:data(station)').map(function(k, v) {
            if ($(v).data('station').gid == station.gid) {
                dupl = true;
                return false;
            }
        });
        console.log('dupl',dupl);
        if (dupl) {

            return false;
        }

        var row = $('<tr>').data('station', station);
        row.append('<td><strong>' + station.nimi + '</strong></td>');
        row.append('<td>' + station.gid + '</td>');
        row.append('<td>' + station.kuntanro + '</td>');
        var dellink = $('<a href="#" class="removeselpys">Poista</a>');
        dellink.click(function(e) {
            $(e.currentTarget).closest('tr').remove();
            return false;
        });

        row.append($('<td>').append(dellink));

        $('#selpys' + groupname).append(row);
    };

    $('.addtogroupbtn').click(function(e) {
        var groupname = $(e.currentTarget).data('group');
        $('#selpys' + groupname + ' tr.empty').remove();
        $('#pysres tr:data(station)').map(function(k, v) {
            addStationToGroup(groupname, $(v).data('station'));
            $(v).remove();

        });
        return false;
    });

    var handlePysakkiFilters = function() {
        var searchsets = {
            "_xsrf": getCookie("_xsrf")
        };
        $('.selpys').each(function(k, selgroup) {
            var selpys = [];
            $(selgroup).children('tr:data(station)').each(function(k, sr) {
                var stationid = $(sr).data('station').gid.toString();
                console.log('stationid',stationid);
                if ($.inArray(stationid, selpys) < 0) selpys.push(stationid);
            });
            searchsets[selgroup.id] = selpys.join(',');
            var selkun = [];

            $(selgroup).children('tr:data(muncip)').each(function(k, sr) {
                var muncipid = $(sr).data('muncip').id;
                if ($.inArray(muncipid, selkun) < 0) selkun.push(muncipid);
            });
            searchsets['muncip_' + selgroup.id] = selkun.join(',');
        });
        return searchsets;
    }

    $('.searchbtn').click(function(e) {

        var searchsets = handlePysakkiFilters();


        $.post('{{reverse_url('reitit.matriisi')}}?format=json', searchsets, function(d) {
            $('#resultsdiv').show(200);
            $('#formdiv').hide(200);
            $('#formhead').text('Näytä hakuvalinnat');
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

    $('#csvoutbtn').click(function(e) {
        var searchsets = handlePysakkiFilters();
        var frm = $('<form method="post" action="{{reverse_url('reitit.matriisi')}}?format=csv">');
        Object.keys(searchsets).forEach(function(k, v) {
            frm.append($('<input type="hidden" name="' + k + '"/>').val(searchsets[k]));
        });
        var sbtn = '<input type="submit" name="s"/>';
        frm.append(sbtn);
        frm.css({'display':'hidden'})
        $('body').append(frm);
        frm.submit();
        frm.remove();
        return false;
    });
    $('#formhead').click(function(e) {
        $('#formdiv').show(200);
        $('#formhead').text('Hakuvalinnat');
        return false;
    });

    $('.emptysel').click(function(e) {
        $(e.currentTarget).closest('table').find('tr:data(station)').remove();
        $(e.currentTarget).closest('table').find('tr:data(muncip)').remove();
        return false;
    });
});
{% endblock %}
</script>
