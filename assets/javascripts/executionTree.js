jQuery2(function() {
	Redcase.ExecutionTree.build();
	jQuery2('#execution_settings_id').on('change', 'select', function() {Redcase.ExecutionTree.tree.refresh()});
});

Redcase.ExecutionTree = {}

Redcase.ExecutionTree.CheckCallback = function() {
	return false;
}

Redcase.ExecutionTree.IsDraggable = function() {
	return true;
}

Redcase.ExecutionTree.getHistory = function(data, node) {
	var escape = function(value) {
		return jQuery2('<span>').text(value == null ? '' : String(value)).html();
	};
	var
	i,
	notFirst,
	color,
	unique = {},
	txt = "<table class='redcase-row' width='100%'>";
	txt += "<tr style='font-weight: bold; background-color: #eeeeee'><td>" + escape(Redcase.labels.label_date) + "</td><td>" + escape(Redcase.labels.label_result) + "</td><td>" + escape(Redcase.labels.label_comments) + "</td><td>" + escape(Redcase.labels.label_executor) + "</td><td>" + escape(Redcase.labels.label_environment) + "</td><td>" + escape(Redcase.labels.label_version) + "</td><td>&nbsp;</td></tr>";
	for (i = 0; i < data.length; i++) {
		
		switch (data[i].result) {
			case "Passed":
				color = "#BBFF88";
				break;
			case "Failed":
				color = "#FFBBBB";
				break;
			case "Not Available":
				color = "#DDDDDD";
				break;
			case "Blocked":
				color = "#CCCCFF";
				break;
			default:
				color = "#FFFFFF";
		}
		notFirst = (unique[data[i].environment + data[i].version]);
		txt += "<tr" + (notFirst ? " style='background-color: " + color + "'" : " style='background-color: " + color + "; font-weight: bold'") + ">";
		txt += "<td>" + escape(data[i].created_on) + "</td>";
		txt += "<td>" + escape(Redcase.resultLabel(data[i].result)) + "</td>";
		txt += "<td>" + escape(data[i].comment) + "</td>";
		txt += "<td>" + escape(data[i].executor) + "</td>";
		txt += "<td>" + escape(data[i].environment) + "</td>";
		txt += "<td>" + escape(data[i].version) + "</td>";
		if(data[i].result != "Passed") {
			var argument = {title: typeof node.text === 'string' ? node.text : node.text(),
						description: data[i].comment,
						environment: data[i].environment,
						version: data[i].version
						}
			txt += '<td>' + jQuery2('<button>', {
				type: 'button', 'class': 'redcase-create-issue', text: Redcase.t('create_issue')
			}).attr('data-issue', JSON.stringify(argument)).prop('outerHTML') + '</td>';
		}
		else {
			txt +="<td>&nbsp;</td>"
		}
		
		txt += "</tr>";
		if (!notFirst) {
			unique[data[i].environment + data[i].version] = 1;
		}
	}
	txt += "</table>";
	return txt;
}

jQuery2(function($) {
	$('#all-results').on('click', '.redcase-create-issue', function() {
		var data = JSON.parse($(this).attr('data-issue'));
		createIssue(data.title, data.description, data.environment, data.version);
	});
});

function createIssue(title, description, environment, version) {
	var apiParams = jQuery2.extend(
		{},
		Redcase.methods.executionJournal.actions.create(), {
			params: {
				'title': title,
				'description': description,
				'environment': environment,
				'version': version,
				'testcase_id': Redcase.ExecutionTree.currentIssue
			},
			success: function(response) {
				Redcase.Combos.refresh();
				console.log(JSON.stringify(response));
				alert(Redcase.t('issue_created', {id: response.issue_id}));
			},
			errorMessage: Redcase.t('issue_failed')
		}
	);
	Redcase.apiCall(apiParams);
}

Redcase.ExecutionTree.selectionChange = function (event, params) {
	var
	node = params.node,
	edit = jQuery2('#test-case-edit');
	edit.hide();
	jQuery2('#all-results-d').hide();
	if (node.original.type == 'case') {
		var apiParms = {};
		jQuery2.extend(apiParms, Redcase.methods.testCase.actions.index(), {
			params: {
				"object_id": node.original.issue_id
			},
			success: function(data) {
				var
				desc,
				subj,
				results,
				version,
				txt,
				apiParms = {};

				Redcase.ExecutionTree.currentIssue = data.issue_id;
				jQuery2('#exec_descr_id').toggle(data.desc !== undefined);
				desc = jQuery2('#test-case-desc');
				subj = jQuery2('#test-case-subj');
				subj.empty().append(jQuery2('<a>').attr('href', '../../issues/' + data.issue_id).text(data.text));
				desc.html(data.desc);
				edit.show();
				results = jQuery2('#results');
				results.val('Passed');
				version = jQuery2('#version');

				jQuery2.extend(apiParms, Redcase.methods.executionJournal.actions.index(), {
					params: {
						"issue_id": node.original.issue_id,
						"version": version.val()
					},
					success: function(data) {
						jQuery2('#all-results-d').toggle(data.length > 0);
						if (data.length > 0) {
							txt = Redcase.ExecutionTree.getHistory(data, node);
							jQuery2('#all-results').html(txt);
						}
					},
					errorMessage: Redcase.t('load_results_failed')
				});
				Redcase.apiCall(apiParms);
				apiParms = {};
				jQuery2.extend(apiParms, Redcase.methods.redcase.actions.getAttachmentURLs(), {
					params: {
						"issue_id": node.original.issue_id
					},
					success: function(data) {
						var txt;
						jQuery2('#test-case-attach').toggle(data.length > 0);
						if (data.length > 0) {
							txt = "";
							for (i = 0; i < data.length; i++) {
								txt += jQuery2('<a>').attr({href: data[i].url, target: '_blank'}).text(data[i].name).prop('outerHTML') + '<br/>';
							}
							jQuery2('#test-case-attach').html(txt);
						}
					},
					errorMessage: Redcase.t('load_attachments_failed')
				});
				Redcase.apiCall(apiParms);
			},
			errorMessage: Redcase.t('load_case_failed', {name: node.text})
		});

		Redcase.apiCall(apiParms);
	}
}

Redcase.ExecutionTree.build = function (params) {
	Redcase.ExecutionTree.tree =
		jQuery2('#execution_test_cases_tree_id').jstree({
			// Core config
			'core' : {
				'force_text' : true,
				'strings' : {'Loading ...': Redcase.t('loading')},
				'check_callback' : Redcase.ExecutionTree.CheckCallback,
				'data' : {
					'type' : 'GET',
					'url' : function() {
						return Redcase.context +
							Redcase.methods.executionSuite.actions.show(
								jQuery2('#list2_id').val()
							).method
					},
					'data' : function() {
						return {
							'version' : jQuery2('#version').val(),
							'environment' : jQuery2('#environments').val()
						}
					}
				},
				'multiple' : false
			}
		});

	// Bind tree events
	Redcase.ExecutionTree.tree.on(
		'select_node.jstree', Redcase.ExecutionTree.selectionChange
	);
	Redcase.ExecutionTree.tree = jQuery2.jstree.reference(
		Redcase.ExecutionTree.tree
	);
}

Redcase.ExecutionTree.selectNextNode = function() {
	var tree =  Redcase.ExecutionTree.tree;
	var nextNode = tree.get_node(
		tree.get_next_dom(tree.get_selected(true)[0], false)
	);
	while (nextNode && (nextNode.original.type !== 'case')) {
		if (nextNode.children.length > 0) {
			tree.open_node(nextNode);
		}
		nextNode = tree.get_node(tree.get_next_dom(nextNode, false));
	}
	if (!nextNode) {
		return;
	}
	tree.deselect_all();
	tree.select_node(nextNode);
};

Redcase.ExecutionTree.execute = function() {
	var issueId = Redcase.ExecutionTree.currentIssue;
	if (!issueId) {
		// TODO: Log something.
		return;
	}
	var tree =  Redcase.ExecutionTree.tree;
	var selectedNode = tree.get_node(tree.get_selected(true)[0], true);
	var result = jQuery2('#results').val();
	var apiParams = jQuery2.extend(
		{},
		Redcase.methods.testCase.actions.update(issueId), {
			params: {
				version: jQuery2('#version').val(),
				result: result,
				envs: jQuery2('#environments').val(),
				comment: jQuery2('#exec-comment').val()
			},
			success: function(data) {
				jQuery2('#all-results-d').toggle(data.length > 0);
				jQuery2('#all-results').html(Redcase.ExecutionTree.getHistory(data, selectedNode));
				tree.set_icon(
					selectedNode,
					('testcase-result-icon-' + result.replace(/\s*/g, ''))
				);
				Redcase.ExecutionTree.selectNextNode();
				jQuery2('#exec-comment').val('');
				// TODO: When a user executes a test case, the results are
				//       getting updated and we need to refresh the Report tab
				//       as well. Triggering combo controls' changes might be
				//       not the best solution, but at least it seems to fix the
				//       issue with updates.
				Redcase.Combos.refresh();
			},
			errorMessage: Redcase.t('execution_failed')
		}
	);
	Redcase.apiCall(apiParams);
}
