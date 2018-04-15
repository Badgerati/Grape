$(document).ready(function() {
    // bind select pickers for default value
    $('.selectpicker').each(function(index, item) {
        var value = $(item).attr('data-value');
        $(item).selectpicker();
        
        if (value) {
            $(item).selectpicker('val', value);
        }
    });

    // set appropriate size for subnav
    var len = $('.subnavbar select').length * 23.5;
    if (len > 0) {
        $('.subnavbar .container').css('width', `${len}%`);
    }

    // bind generic events
    bindGenericEvents();
});


function bindGenericEvents() {
    // bind clickable rows
    $('.clickable-row').unbind().click(function() {
        window.location = $(this).data('href');
    });

    // bind events on nav-tab bars
    $('ul.nav-tabs li').unbind().click(function(event) {
        var _this = $(this);
        var _content = _this.closest('.nav-tabs-content');
        var _active = _this.closest('ul.nav-tabs').find('li.active');

        // hide the currently active tab
        _active.removeClass('active');
        _content.find('#' + _active.attr('data-section')).addClass('hidden');

        // show the now focus tab
        _this.addClass('active');
        _content.find('#' + _this.attr('data-section')).removeClass('hidden');
    });

    // bind expandable sections
    $('span.expandable').unbind().click(function(event) {
        var section = $(this).data('section');
        $(this).closest('div').find('div.' + section).slideToggle();
    });
}


function scrollToTop() {
    document.body.scrollTop = document.documentElement.scrollTop = 0;
}


function doAjaxCall(url, method, data, callback, form, submit, input, reverter) {
    $.ajax({
        url: url,
        type: method,
        data: data,
        crossDomain: true,
        success: function(data) {
            if (form || submit) {
                var _submit = submit || findSubmit(form);

                if (data.error) {
                    setFailure(_submit, 'Failed', 3000);

                    if (form) {
                        showAlert(data.errorKey, form, data.message, input);
                    }
                    
                    return;
                }

                if (input) {
                    $(input).val('').blur();
                }

                setSuccess(_submit, 'Success', 3000, reverter);
                hideAlert(null, form);
                unfocusSubmit(null, form);
            }

            if (callback) {
                if (data.error) {
                    console.log(data.message);
                }

                callback(null, data);
            }
        },
        error: function(err) {
            if (form || submit) {
                setFailure((submit || findSubmit(form)), 'Failed', 3000);

                if (form) {
                    showAlert((form ? null : 'error'), form, 'An unexpected has error occurred', input);
                }
            }

            if (callback) {
                if (err) {
                    console.log(err);
                }
                
                callback(err, null);
            }
        }
    });
}


function bindSelectChange(name, func) {
    if (!name || !func) {
        return;
    }

    $('select#' + name + '.selectpicker').on('change', () => func());
}


function bindRefreshToggle(func, millis) {
    if (!func) {
        return;
    }

    if (!millis || millis < 10000) {
        millis = 10000;
    }

    $('#refresh-toggle').unbind().click(function() {
        $(this).toggleClass('btn-default').toggleClass('btn-success');

        if ($(this).hasClass('btn-success')) {
            var id = setInterval(func, millis);
            $(this).data('interval-id', id);
        }
        else {
            clearInterval($(this).data('interval-id'));
            $(this).removeData('interval-id');
        }
    });
}


function getSubNavFilters() {
    return {
        provider: getSelectOption('provider', 'All', true),
        environment: getSelectOption('environment', 'All', true)
    };
}


function getSelectOption(name, defaultValue, blankOnDefault) {
    if (!name) {
        return (defaultValue || '');
    }

    var value = $('select#' + name +'.selectpicker').selectpicker('val');

    if ((value == defaultValue) && blankOnDefault) {
        return '';
    }

    return (value || defaultValue || '');
}


function showProgress(name, location) {
    if (!name || !location) {
        return;
    }

    var html = 
        '<div id="' + name + '" class="progress">' +
            '<div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%"></div>' +
        '</div>';
        
    $(location).prepend(html);
}


function hideProgress(name) {
    if (!name) {
        return;
    }

    $(name).remove();
}


function generateStatusLabel(state) {
    switch (state.toLowerCase()) {
        case 'success':
            return '<span class="label label-success">' + state + '</span>';

        case 'failure':
            return '<div class="label label-danger">' + state + '</div>';

        case 'running':
            return '<span class="label label-primary">' + state + '</span>';

        case 'pending':
            return '<span class="label label-default">' + state + '</span>';
    }
}


function generateStateLabel(state) {
    var str = state.toString();

    switch (str.toLowerCase()) {
        case 'on':
            return `<span class="label label-success">${str.toUpperCase()}</span>`;

        case 'off':
        case 'deleting':
            return `<div class="label label-danger">${str.toUpperCase()}</div>`;

        case 'booting':
        case 'allocating':
        case 'rebooting':
        case 'provisioning':
            return `<div class="label label-primary">${str.toUpperCase()}</div>`;

        case 'deallocating':
        case 'shutting down':
            return `<div class="label label-warning">${str.toUpperCase()}</div>`;
    }
}


function generateLink(url) {
    if (!url || !url.startsWith('http')) {
        return url;
    }

    return `<a href="${url}">${url}</a>`
}


function appendTablePipelineRows(opts) {
    if (!opts.pipelines || opts.pipelines.length == 0) {
        return;
    }

    var values = null,
        stage = null,
        vm = null;

    opts.pipelines.forEach((v) => {
        stage = v.finished
            ? 'Completed'
            : ((v.stage && v.stage.length > 0) ? v.stages[v.stages.length - 1].type : 'Pending...');

        vm = (v.vms && v.vms.length > 0) ? v.vms[0].name : 'N/A';

        values = [
            generateStatusLabel(v.state),
            v.name,
            v.trigger,
            stage,
            v.provider,
            v.environment,
            vm,
            '<span class="glyphicon glyphicon-time" aria-hidden="true"></span>' + formatTime(v.duration)
        ];

        var url = (opts.includeUrl ? '/pipelines/' + v.id : null);
        var row = appendTableRow(opts.table, values, v.id, url, false);
        $(row).addClass('clickable');
    });

    bindGenericEvents();
}


function appendTableRow(table, values, id, url, centreFirst) {
    if (!table || !values || values.length == 0) {
        return;
    }

    // build the row
    var _class = url ? 'class="clickable-row"' : '';
    var _href = url ? 'data-href="' + url + '"' : '';
    var row = '<tr data-id="' + (id || '') + '" ' + _class + ' ' + _href + '>';

    values.forEach((v, i) => {
        row += ('<td' + (centreFirst && i == 0 ? ' class="centre"' : '')  + '>' + v + '</td>')
    });

    row += '</tr>';

    // append the row to the table
    $(table).find('tbody:nth(0)').append(row);

    // return the row that was just appened
    return id
        ? $(table).find('tbody:nth(0) tr[data-id="' + id + '"]')
        : null;
}


function appendCodeBlock(element, content, id, noLineNos) {
    if (!element || !content || content.length == 0 || !id) {
        return;
    }

    $(element).append(`<pre class="code" id="${id}"></pre>`);

    $(`#${id}`).html(noLineNos ? content : addLineNumbers(content));
}


function appendNavTabs(element, titles, opts) {
    if (!element || !titles || titles.length == 0) {
        return;
    }

    // opts
    if (!opts) {
        opts = {};
    }

    if (!opts.name) {
        opts.name = '';
    }

    // titles
    var tabTitles = '';
    titles.forEach((v, i) => {
        tabTitles += `
            <li role="presentation" data-section="${v}${opts.name}-tab" class="${i == 0 ? 'active' : ''}">
                <a href="#">${v}</a>
            </li>`;
    });

    // panels
    var tabPanels = '';
    var tabData = '';

    titles.forEach((v, i) => {
        tabData = '';
        if (opts.data && Object.keys(opts.data).length > 0) {
            Object.keys(opts.data).forEach((v) => {
                tabData += `data-${v}="${opts.data[v][i]}" `
            });
        }

        tabPanels += `
            <div id="${v}${opts.name}-tab" class="${i == 0 ? '' : 'hidden'}" ${tabData.trim()}>
                <div id="${v}${opts.name}-panel" class="panel-body panel-board dark">
                    <div id="${v}${opts.name}-error" class="alert alert-danger mTop0 hidden" role="alert"></div>
                </div>
            </div>`;
    });

    // add panels to titles
    var tabs = `
        <div class="nav-tabs-content">
            <ul class="nav nav-tabs" role="tablist">
                ${tabTitles}
            </ul>
            <div class="nav-tabs-data">
                ${tabPanels}
            </div>
        </div>`;

    // append
    $(element).append(tabs);

    // hook tab events
    bindGenericEvents();
}


function clearTable(element) {
    $(element).find('tbody:nth(0) tr').remove();
}


function clearList(element) {
    $(element).find('li').remove();
}


function setSuccess(button, message, timeout, reverter) {
    var _button = $(button);
    var html = _button.html();

    _button.removeClass('btn-default').addClass('btn-success');
    _button.html('<span class="glyphicon glyphicon-ok" aria-hidden="true"></span> ' + message);

    if (timeout) {
        setTimeout(function() {
            if (reverter) {
                reverter(_button);
            }
            else {
                _button.removeClass('btn-success').addClass('btn-default');
                _button.html(html);
            }
        }, timeout);
    }
}


function setFailure(button, message, timeout, reverter) {
    var _button = $(button);
    var html = _button.html();

    _button.removeClass('btn-default').addClass('btn-danger');
    _button.html('<span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> ' + message);

    if (timeout) {
        setTimeout(function() {
            if (reverter) {
                reverter(_button);
            }
            else {
                _button.removeClass('btn-danger').addClass('btn-default');
                _button.html(html);
            }
        }, timeout);
    }
}


function showAlert(error, element, message, input, timeout) {
    message = (message.statusText || message);

    if (validator.isEmpty(message)) {
        return;
    }

    if (error && !error.startsWith('#')) {
        error = '#' + error;
    }
    else if (!error) {
        if (!element) {
            return;
        }

        error = $(element).find('.alert');
        if (!error || error.length == 0) {
            error = $(element).closest('div.input-container').find('.alert');
        }
    }

    if (!error) {
        return;
    }

    $(error).text(message);
    slideDown(error, timeout);

    // refocus the input box
    if (element) {
        unfocusSubmit(null, element);
    }

    if (input) {
        focusInput(input);
    }
}


function hideAlert(name, element, duration) {
    var doHide = function(name, form, duration) {
        if (name && !name.startsWith('#')) {
            name = '#' + name;
        }
        else if (!name) {
            if (!element) {
                return;
            }

            name = $(element).find('.alert');
            if (!name || name.length == 0) {
                name = $(element).closest('div.input-container').find('.alert');
            }
        }

        slideUp(name, duration);
    }

    // loop through name, or do single
    if (name instanceof Array) {
        name.forEach((v, i) => {
            doHide(v, element, (duration || 0));
        });
    }
    else {
        doHide(name, element, duration);
    }
}


function slideUp(element, duration) {
    var _element = $(element);

    if (_element && _element.is(':visible')) {
        if (duration == null) {
            _element.slideUp();
        }
        else {
            _element.slideUp(duration);
        }
    }
}


function slideDown(element, timeout) {
    var _element = $(element);

    if (_element && !_element.is(':visible')) {
        _element.hide().removeClass('hidden').slideDown();

        if (timeout) {
            setTimeout(function() {
                slideUp(element);
            }, timeout);
        }
    }
}


function unfocusSubmit(submit, form) {
    submit = submit || findSubmit(form);

    if (submit) {
        $(submit).blur();
    }
}


function focusInput(input) {
    if (!input) {
        return;
    }

    setTimeout(function() {
        $(input).focus();
    }, 100);
}


function findSubmit(form) {
    if (!form) {
        return null;
    }

    return $(form).find("[type='submit']");
}


function formatNumber(value)
{
    value += '';
    var split = value.split('.');
    var first = split[0];
    var rgx = /(\d+)(\d{3})/;

    while (rgx.test(first)) {
        first = first.replace(rgx, '$1' + ',' + '$2');
    }

    var second = split.length > 1 ? '.' + split[1] : '';
    return first + second;
}


function formatTime(time) {
    return moment.duration(time).humanize();
}


function formatDate(date) {
    return moment(date).format('YYYY[-]MM[-]DD HH[:]mm[:]ss');
}


function getDuration(start, end) {
    start = moment(start);
    end = moment(end);
    return formatTime(end.diff(start));
}


function disableElement(element) {
    $(element).attr('disabled', 'disabled');
}


function enableElement(element) {
    $(element).removeAttr('disabled');
}


function getCurrentPage(element) {
    return parseInt($(element).find('li.active span').text());
}


function bindPagination(pagingId, current, total, action, opts) {
    clearList(pagingId);

    for (var i = 1; i <= total; i++) {
        var link = (i == current)
            ? '<li class="active"><span>' + i + '</span></li>'
            : '<li><span>' + i + '</span></li>';
        $(pagingId).append(link);
    }

    $(pagingId).find('li').click(function() {
        if ($(this).hasClass('active')) {
            return;
        }

        $(pagingId).find('li.active').toggleClass('active');
        $(this).toggleClass('active');

        action(getCurrentPage(pagingId), opts);
        scrollToTop();
    });
}


function repeatString(str, num) {
    var v = '';

    for(var i = 0; i < num; i++)
    {
        v += str;
    }

    return v;
}


function padLeft(str, num) {
    return repeatString(' ', num - `${str}`.length) + str;
}


function getTabPadding(str, max) {
    if (!str || str.length == 0) {
        return (str + repeatString('\t', max));
    }

    var amount = Math.floor(str.length / 8);
    return (str + repeatString('\t', max - amount));
}


function addLineNumbers(str) {
    var start       = 1;
    var isArray     = Array.isArray(str);
    var lines       = (isArray ? str : str.split("\n"));
    var end         = start + lines.length - 1;
    var width       = String(end).length

    var numbered  = lines.map((line, index) => {
        return (' ' + padLeft(start + index, width) + ' | ' + line.replace('ï»¿', ''));
    });

    return (isArray ? numbered : numbered.join("\n"));
}