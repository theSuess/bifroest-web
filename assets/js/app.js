// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";
import "bootstrap";
import "bootstrap-select";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
$(document).off('click.bs.dropdown.data-api', '.dropdown form');


$(document).ready(function() {
    //initialize wizard
    var completeWizard = new wizard("#createServer");
    // Row Checkbox Selection
    $("input[type='checkbox']").change(function(e) {
        if ($(this).is(":checked")) {
            $(this).closest('.list-group-item').addClass("active");
        } else {
            $(this).closest('.list-group-item').removeClass("active");
        }
    });
    $('#lbSubmitButton').click(createLoadbalancer);
    $('.delete-domain').click(withAttr('domainId', deleteDomain));
    $('.approve-user').click(withAttr('userId', approveUser));
    $('.reject-user').click(withAttr('userId', rejectUser));
    $('.make-admin').click(withAttr('userId', makeUserAdmin));
    $('#editSave').click(withAttr('domainId',saveDomain));
    $('#flavor-input').on('change',(event) => {
        let data = event.target.selectedOptions[0].dataset;
        $('#flavor-detail-ram').text(humanFileSize(data.ram * 1000 * 1000,true));
        $('#flavor-detail-vcpus').text(data.vcpus);
    });
    $('#keypair-input').on('change',(event) => {
        let data = event.target.selectedOptions[0].dataset;
        $('#keypair-detail-fingerprint').text(data.fingerprint);
    });
    $('#public-input').on('change',(event) => {
        if(event.target.checked){
            $('#network-details').removeClass('hidden');
        } else {
            $('#network-details').addClass('hidden');
        }
    });
    $('#editModal').on('show.bs.modal',(event) => {
        let button = $(event.relatedTarget);
        let domain = button.data('domain');
        let username = button.data('username');
        let server_addr = button.data('server-addr');
        let id = button.data('id');
        var modal = $(this);
        modal.find('.modal-title').text('Edit domain: ' + domain);
        $('#editModal-host').val(server_addr);
        $('#editModal-domain').val(domain);
        $('#editModal-user').val(username);
        $('#editDelete').data('domainId',id);
        $('#editSave').data('domainId',id);
    });

    var table = $('#domain-table').DataTable({
        select: {
            selector: 'td:first-child input[type="checkbox"]',
            style: 'multi'
        },
        columns: [
            {name: "select",orderable: false},
            {name: "domain",orderable: true},
            {name: "user",orderable: true},
            {name: "server_addr",orderable: true},
            {name: "inserted_at",orderable: true},
            {name: "actions",orderable: false},
        ],
        order: [[1,'asc']]
    });
    $('#selectAll').click(() => {
        $('.row-select').click();
    });
    $('.wizard-pf-complete button').click(() => window.location.replace('/'));
});

function withAttr(attr, fn) {
    return function(e) {
        var attrVal = $(e.target).data(attr);
        if (attrVal === undefined) {
            attrVal = $(e.target).parent().data(attr);
        }
        fn(attrVal);
    };
}

function humanFileSize(bytes, si) {
    var thresh = si ? 1000 : 1024;
    if(Math.abs(bytes) < thresh) {
        return bytes + ' B';
    }
    var units = si
        ? ['kB','MB','GB','TB','PB','EB','ZB','YB']
        : ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
    var u = -1;
    do {
        bytes /= thresh;
        ++u;
    } while(Math.abs(bytes) >= thresh && u < units.length - 1);
    return bytes.toFixed(1)+' '+units[u];
}

function saveDomain(id) {
    let host = $('#editModal-host').val();
    let domain = $('#editModal-domain').val();
    $.ajax({
        url: `/api/domains/${id}`,
        type: 'PUT',
        data: {
            domain: {
                server_addr: host,
                domain: domain
            }
        }
    })
    .done(() => window.location.reload())
    .fail(() => alert('Failed!'));
}

function makeUserAdmin(id) {
    if (!confirm('Are you sure you want to make this user an Administrator?')) {
        return;
    }
    $.ajax({
            url: `/api/users/${id}`,
            type: 'PUT',
            data: {
                admin: true
            }
        })
        .done(() => window.location.reload())
        .fail(() => alert('Failed!'));
}

function rejectUser(id) {
    $.ajax({
            url: `/api/users/${id}`,
            type: 'PUT',
            data: {
                approved: false
            }
        })
        .done(() => window.location.reload())
        .fail(() => alert('Failed!'));
}

function approveUser(id) {
    $.ajax({
            url: `/api/users/${id}`,
            type: 'PUT',
            data: {
                approved: true
            }
        })
        .done(() => window.location.reload())
        .fail(() => alert('Failed!'));
}

function deleteDomain(id) {
    $.ajax({
            url: `/api/domains/${id}`,
            type: 'DELETE'
        })
        .done(() => window.location.reload())
        .fail(() => alert('Failed!'));
}

function createLoadbalancer() {
    var subdomain = $('#textInput-modal-subdomain').val();
    var host = $('#textInput-modal-host').val();
    if (!$('#lbForm')[0].checkValidity()) {
        $('<input type="submit">').hide().appendTo($('#lbForm')).click().remove();
        return;
    }
    toggleSpinner($('#lbSubmitButton'));
    $.post('/api/domains', {
            domain: {
                domain: subdomain,
                server_addr: host
            }
        }).done(() => {
            window.location.reload();
        })
        .fail((data) => {
            toggleSpinner($('#lbSubmitButton'));
            var errors = data.responseJSON.errors;
            if (errors.domain) {
                setError($('#form-group-subdomain'), errors.domain[0]);
            }
            if (errors.server_addr) {
                setError($('#form-group-host'), errors.server_addr[0]);
            }
        });
}

function createServer(domain,flavorRef,imageRef,name,pub,keyName) {
    return new Promise((resolve) => {
            $.ajax({
            url: `/api/domains`,
            contentType: 'application/json',
            dataType: 'json',
            type: 'POST',
            data: JSON.stringify({
                domain: {
                    domain: domain
                },
                server: {
                    flavorRef: flavorRef,
                    imageRef: imageRef,
                    name: name,
                    key_name: keyName,
                    public: pub
                }
            })
        }).done(resolve);
    });
}

function setError(formgroup, error) {
    formgroup.addClass('has-error');
    formgroup.find('.help-block').removeClass('hidden').text(error);
}

function toggleSpinner(button) {
    button.find('.spinner').toggleClass('hidden');
    button.find('span').toggleClass('hidden');
}

var wizard = function(id) {
    var self = this,
        modal, tabs, tabCount, tabLast, currentGroup, currentTab, contents;
    self.id = id;

    $(self.id).click(function() {
        self.init(this);
    });

    this.init = function(button) {
        // get id of open modal
        self.modal = $(button).data("target");

        // open modal
        $(self.modal).modal('show');
        // adjust height of contents row (while steps and sidebar are hidden and loading message displays)
        self.updateWizardLayout();

        // assign data attribute to all tabs
        $(self.modal + " .wizard-pf-sidebar .list-group-item").each(function() {
            // set the first digit (i.e. n.0) equal to the index of the parent tab group
            // set the second digit (i.e. 0.n) equal to the index of the tab within the tab group
            $(this).attr("data-tab", ($(this).parent().index() + 1 + ($(this).index() / 10 + .1)));
        });
        // assign data attribute to all tabgroups
        $(self.modal + " .wizard-pf-sidebar .list-group").each(function() {
            // set the value equal to the index of the tab group
            $(this).attr("data-tabgroup", ($(this).index() + 1));
        });

        // create array of all tabs, using the data attribute, and determine the last tab
        self.tabs = $(self.modal + " .wizard-pf-sidebar .list-group-item").map(function() {
            return $(this).data("tab");
        });
        self.tabCount = self.tabs.length;
        self.tabSummary = self.tabs[self.tabCount - 2]; // second to last tab displays summary
        self.tabLast = self.tabs[self.tabCount - 1]; // last tab displays progress
        // set first tab group and tab as current tab
        // if someone wants to target a specific tab, that could be handled here
        self.currentGroup = 1;
        self.currentTab = 1.1;
        self.updateTabGroup();
        // hide loading message
        $(self.modal + " .wizard-pf-loading").addClass("hidden");
        // show tabs and tab groups
        $(self.modal + " .wizard-pf-steps").removeClass("hidden");
        $(self.modal + " .wizard-pf-sidebar").removeClass("hidden");
        // remove active class from all tabs
        $(self.modal + " .wizard-pf-sidebar .list-group-item.active").removeClass("active");
        // apply active class to new current tab and associated contents
        self.updateActiveTab();
        // adjust height of contents row (while steps and sidebar and tab contents are visible)
        self.updateWizardLayout();
        self.updateWizardFooterDisplay();

        //initialize click listeners
        self.tabGroupSelect();
        self.tabSelect();
        self.backBtnClicked();
        self.nextBtnClicked();
        self.finishBtnClick();
        self.cancelBtnClick();

        $(window).resize(function() {
            self.updateWizardLayout();
        });
    };

    // update which tab group is active
    this.updateTabGroup = function() {
        $(self.modal + " .wizard-pf-step.active").removeClass("active");
        $(self.modal + " .wizard-pf-step[data-tabgroup='" + self.currentGroup + "']").addClass("active");
        $(self.modal + " .wizard-pf-sidebar .list-group").addClass("hidden");
        $(self.modal + " .list-group[data-tabgroup='" + self.currentGroup + "']").removeClass("hidden");
    };

    // update which tab is active
    this.updateActiveTab = function() {
        if(self.currentTab == self.tabSummary){
            $('#review-name').text($('#name-input').val());
            $('#review-image').text($('#image-input option:selected').text());
            $('#review-flavor').text($('#flavor-input option:selected').text());
            $('#review-keypair').text($('#keypair-input option:selected').text());
            $('#review-networks').text($('#public-input')[0].checked);
            $('#review-subdomain').text($('#subdomain-input').val());
        }
        $(self.modal + " .list-group-item[data-tab='" + self.currentTab + "']").addClass("active");
        self.updateVisibleContents();
    };

    // update which contents are visible
    this.updateVisibleContents = function() {
        var tabIndex = ($.inArray(self.currentTab, self.tabs));
        // displaying contents associated with currentTab
        $(self.modal + " .wizard-pf-contents").addClass("hidden");
        $(self.modal + " .wizard-pf-contents:eq(" + tabIndex + ")").removeClass("hidden");
        // setting focus to first form field in active contents
        setTimeout(function() {
            $(".wizard-pf-contents:not(.hidden) form input, .wizard-pf-contents:not(.hidden) form textarea, .wizard-pf-contents:not(.hidden) form select").first().focus(); // this does not account for disabled or read-only inputs
        }, 100);
    };

    // update display state of Back button
    this.updateBackBtnDisplay = function() {
        if (self.currentTab == self.tabs[0]) {
            $(self.modal + " .wizard-pf-back").addClass("disabled");
        }
    };

    // update display state of next/finish button
    this.updateNextBtnDisplay = function() {
        if (self.currentTab == self.tabSummary) {
            $(self.modal + " .wizard-pf-next").addClass("hidden");
            $(self.modal + " .wizard-pf-finish").removeClass("hidden");
        } else {
            $(self.modal + " .wizard-pf-finish").addClass("hidden");
            $(self.modal + " .wizard-pf-next").removeClass("hidden");
        }
    };

    // update display state of buttons in the footer
    this.updateWizardFooterDisplay = function() {
        $(self.modal + " .wizard-pf-footer .disabled").removeClass("disabled");
        self.updateBackBtnDisplay();
        self.updateNextBtnDisplay();
    };

    // adjust layout of panels in wizard
    this.updateWizardLayout = function() {
        var top = ($(self.modal + " .modal-header").outerHeight() + $(self.modal + " .wizard-pf-steps").outerHeight()) + "px",
            bottom = $(self.modal + " .modal-footer").outerHeight() + "px",
            sidebarwidth = $(self.modal + " .wizard-pf-sidebar").outerWidth() + "px";
        $(self.modal + " .wizard-pf-row").css("top", top);
        $(self.modal + " .wizard-pf-row").css("bottom", bottom);
        $(self.modal + " .wizard-pf-main").css("margin-left", sidebarwidth);
    };

    // when the user clicks a step, then the tab group for that step is displayed
    this.tabGroupSelect = function() {
        $(self.modal + " .wizard-pf-step>a").click(function() {
            // remove active class active tabgroup and add active class to the
            // clicked tab group (but don't remove the active class from current tab)
            self.currentGroup = $(this).parent().data("tabgroup");
            self.updateTabGroup();
            // update value for currentTab -- if a tab is already marked as active
            // for the new tab group, use that, otherwise set it to the first tab
            // in the tab group
            self.currentTab = $(self.modal + " .list-group[data-tabgroup='" + self.currentGroup + "'] .list-group-item.active").data("tab");
            if (self.currentTab == undefined) {
                self.currentTab = $(self.modal + " .list-group[data-tabgroup='" + self.currentGroup + "'] .list-group-item:first-child").data("tab");
                // apply active class to new current tab and associated contents
                self.updateActiveTab();
            } else {
                // use already active tab and just update contents
                self.updateVisibleContents();
            }
            // show/hide/disable/enable buttons if needed
            self.updateWizardFooterDisplay();
        });
    };

    // when the user clicks a tab, then the tab contents are displayed
    this.tabSelect = function() {
        $(self.modal + " .wizard-pf-sidebar .list-group-item>a").click(function() {
            // update value of currentTab to new active tab
            self.currentTab = $(this).parent().data("tab");
            // remove active class from active tab in current active tab group (i.e.
            // don't remove the class from tabs in other groups)
            $(self.modal + " .list-group[data-tabgroup='" + self.currentGroup + "'] .list-group-item.active").removeClass("active");
            // add active class to the clicked tab and the associated contents
            $(this).parent().addClass("active");
            self.updateVisibleContents();
            if (self.currentTab == self.tabLast) {
                $(self.modal + " .wizard-pf-next").addClass("hidden");
                $(self.modal + " .wizard-pf-finish").removeClass("hidden");
                self.finish();
            } else {
                // show/hide/disable/enable buttons if needed
                self.updateWizardFooterDisplay();
            }
        });
    };

    // Back button clicked
    this.backBtnClicked = function() {
        $(self.modal + " .wizard-pf-back").click(function() {
            // if not the first page
            if (self.currentTab != self.tabs[0]) {
                // go back a page (i.e. -1)
                self.wizardPaging(-1);
                // show/hide/disable/enable buttons if needed
                self.updateWizardFooterDisplay();
            }
        });
    };

    // Next button clicked
    this.nextBtnClicked = function() {
        $(self.modal + " .wizard-pf-next").click(function() {
            // go forward a page (i.e. +1)
            self.wizardPaging(1);
            // show/hide/disable/enable buttons if needed
            self.updateWizardFooterDisplay();
        });
    };

    // Finish button clicked
    // Deploy/Finish button would only display during the second to last step.
    this.finishBtnClick = function() {
        $(self.modal + " .wizard-pf-finish").click(function() {
            self.wizardPaging(1);
            self.finish();
        });
    };

    // Cancel/Close button clicked
    this.cancelBtnClick = function() {
        $(self.modal + " .wizard-pf-dismiss").click(function() {
            // close the modal
            $(self.modal).modal('hide');
            // drop click event listeners
            $(self.modal + " .wizard-pf-step>a").off("click");
            $(self.modal + " .wizard-pf-sidebar .list-group-item>a").off("click");
            $(self.modal + " .wizard-pf-back").off("click");
            $(self.modal + " .wizard-pf-next").off("click");
            $(self.modal + " .wizard-pf-finish").off("click");
            $(self.modal + " .wizard-pf-dismiss").off("click");
            // reset final step
            $(self.modal + " .wizard-pf-process").removeClass("hidden");
            $(self.modal + " .wizard-pf-complete").addClass("hidden");
            // reset loading message
            $(self.modal + " .wizard-pf-contents").addClass("hidden");
            $(self.modal + " .wizard-pf-loading").removeClass("hidden");
            // remove tabs and tab groups
            $(self.modal + " .wizard-pf-steps").addClass("hidden");
            $(self.modal + " .wizard-pf-sidebar").addClass("hidden");
            // reset buttons in final step
            $(self.modal + " .wizard-pf-close").addClass("hidden");
            $(self.modal + " .wizard-pf-cancel").removeClass("hidden");
        });
    };

    // when the user clicks Next/Back, then the next/previous tab and contents display
    this.wizardPaging = function(direction) {
        // get n.n value of next tab using the index of next tab in tabs array
        var tabIndex = ($.inArray(self.currentTab, self.tabs)) + direction;
        var newTab = self.tabs[tabIndex];
        // add/remove active class from current tab group
        // included math.round to trim off extra .000000000002 that was getting added
        if (newTab != Math.round(10 * (direction * .1 + self.currentTab)) / 10) {
            // this statement is true when the next tab is in the next tab group
            // if next tab is in next tab group (e.g. next tab data-tab value is
            // not equal to current tab +.1) then apply active class to next
            // tab group and step, and update the value for var currentGroup +/-1
            self.currentGroup = self.currentGroup + direction;
            self.updateTabGroup();
        }
        self.currentTab = newTab;
        // remove active class from active tab in current tab group
        $(self.modal + " .list-group[data-tabgroup='" + self.currentGroup + "'] .list-group-item.active").removeClass("active");
        // apply active class to new current tab and associated contents
        self.updateActiveTab();
    };

    // This code keeps the same contents div active, but switches out what
    // contents display in that div (i.e. replaces process message with
    // success message).
    this.finish = function() {
        $(self.modal + " .wizard-pf-back").addClass("disabled"); // if Back remains enabled during this step, then the Close button needs to be removed when the user clicks Back
        $(self.modal + " .wizard-pf-finish").addClass("disabled");


        let name = $('#name-input').val();
        let image = $('#image-input').val();
        let flavor = $('#flavor-input').val();
        let keypair = $('#keypair-input').val();
        let domain = $('#subdomain-input').val();
        let keyName = $('#keypair-input').val();
        let pub = $('#public-input')[0].checked;
        if(keyName === 'None'){
            keyName = undefined;
        }

        createServer(domain,flavor,image,name,pub,keyName).then(() => {
            $(self.modal + " .wizard-pf-cancel").addClass("hidden");
            $(self.modal + " .wizard-pf-finish").addClass("hidden");
            $(self.modal + " .wizard-pf-close").removeClass("hidden");
            $(self.modal + " .wizard-pf-process").addClass("hidden");
            $(self.modal + " .wizard-pf-complete").removeClass("hidden");
        });
    };

};
