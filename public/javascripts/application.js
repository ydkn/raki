/* 
 * Raki - extensible rails-based wiki
 * Copyright (C) 2010 Florian Schwab & Martin Sigloch
 */

var csrfParam;
var csrfTocken;
var urlPrefix;
var namespace;
var page;
var action;
var viewUrl;
var editUrl;
var previewUrl;

function initMetaVars() {
	metaTags = document.getElementsByTagName("meta");
	for(i = 0; i < metaTags.length; i++) {
		name = metaTags[i].getAttribute('name');
		value = metaTags[i].getAttribute('content');
		if(name == 'csrf-param') {
			csrfParam = value
		} else if(name == 'csrf-token') {
			csrfTocken = value;
		} else if(name == 'raki-url-prefix') {
			urlPrefix = value;
		} else if(name == 'raki-namespace') {
			namespace = value;
		} else if(name == 'raki-page') {
			page = value;
		} else if(name == 'raki-action') {
			action = value;
		} else if(name == 'raki-view-url') {
			viewUrl = value;
		} else if(name == 'raki-edit-url') {
			editUrl = value;
		} else if(name == 'raki-preview-url') {
			previewUrl = value;
		}
	}
}

function initEditButtons() {
	editForm = document.getElementById('edit-form');
	editPreview = document.getElementById('edit-preview');
	editAbort = document.getElementById('edit-abort');
	editSave = document.getElementById('edit-save');
	
	if(editForm && editPreview && editAbort && editSave) {
		editPreview.onclick = function(e) {
			doUnlock = false;
			editForm.action = previewUrl;
			editForm.submit();
		}
		editAbort.onclick = function(e) {
			window.location = viewUrl;
		}
		editSave.onclick = function(e) {
			doUnlock = false;
		}
	}
	
	previewForm = document.getElementById('preview-form');
	previewEdit = document.getElementById('preview-edit');
	previewAbort = document.getElementById('preview-abort');
	previewSave = document.getElementById('preview-save');
	
	if(previewForm && previewEdit && previewAbort && previewSave) {
		previewEdit.onclick = function(e) {
			doUnlock = false;
			previewForm.action = editUrl;
			previewForm.submit();
		}
		previewAbort.onclick = function(e) {
			window.location = viewUrl;
		}
		previewSave.onclick = function(e) {
			doUnlock = false;
		}
	}
}

function toolbarClickEvent(e) {
	toolbarItem = (e.srcElement ? e.srcElement : e.target).parentNode;
	
	if (toolbarItem.tagName.toLowerCase() != "a") {
		return;
	}
	
	itemAttributes = toolbarItem.attributes;
	
	var content = document.getElementById('content');
	var selectionStart = content.selectionStart;
	var selectionEnd = content.selectionEnd;
	var selectedText = content.value.substring(content.selectionStart, content.selectionEnd);

	var params = new Object();
	for(i = 0; i < itemAttributes.length; i++) {
		attrName = toolbarItem.attributes[i].name;
		attrValue = toolbarItem.attributes[i].value;
		if(attrName.match("^data-")) {
			params[attrName.substring(5, attrName.length)] = attrValue;
		}
	}
	
	newContent = content.value;
	newSelectionStart = selectionStart;
	newSelectionEnd = selectionEnd;
	
	if(params['enclosed']) {
		newContent = content.value.substring(0, selectionStart) + params['enclosed'] + selectedText + params['enclosed'] + content.value.substring(selectionEnd, content.value.length);
		newSelectionStart = selectionStart + 1;
		newSelectionEnd = newSelectionStart + selectedText.length;
	} else if(params['prefix'] || params['suffix']) {
		newSelectedText = selectedText;
		newSelectionStart = selectionStart;
		newSelectionEnd = selectionEnd;
		if(params['prefix']) {
			newSelectedText = params['prefix'] + newSelectedText;
			newSelectionStart++;
			newSelectionEnd++;
		}
		if(params['suffix']) {
			newSelectedText = newSelectedText + params['suffix'];
		}
		newContent = content.value.substring(0, selectionStart) + newSelectedText + content.value.substring(selectionEnd, content.value.length);
	}
	if(params['line-start']) {
		for(i = selectionStart; i >= 0; i--) {
			if((content.value.charAt(i-1) == "\n") || (i == 0)) {
				pre = content.value.substring(0, i);
				post = content.value.substring(i, content.value.length);
				newContent = pre + params['line-start'] + post;
				newSelectionStart = selectionStart + params['line-start'].length;
				newSelectionEnd = selectionEnd + params['line-start'].length;
				break;
			}
		}
	}
	if(params['line-end']) {
		for(i = selectionEnd; i < content.value.length; i++) {
			if((content.value.charAt(i) == "\n") || (i == content.value.length)) {
				pre = content.value.substring(0, i);
				post = content.value.substring(i, content.value.length);
				newContent = pre + params['line-end'] + post;
				break;
			}
		}
	}
	if(params['multiline-start']) {
		pre = content.value.substring(0, selectionStart);
		post = content.value.substring(selectionEnd, content.value.length);
		newContent = content.value.substring(selectionStart, selectionEnd);
		if((selectionStart != 0) && (content.value.charAt(selectionStart) != "\n")) {
			if(content.value.charAt(selectionStart-1) != "\n") {
				pre += "\n";
				newSelectionEnd++;
			}
			pre += params['multiline-start'];
			newSelectionStart++;
			newSelectionEnd += params['multiline-start'];
		}
		if(selectionStart == 0) {
			pre += params['multiline-start'];
			newSelectionEnd += params['multiline-start'];
		}
		for(i = 0; i < newContent.length; i++) {
			if(newContent.charAt(i) == "\n") {
				newContentPre = newContent.substring(0, i+1);
				newContentPost = newContent.substring(i+1, newContent.length);
				newContent = newContentPre + params['multiline-start'] + newContentPost;
				newSelectionEnd += params['multiline-start'];
				i += 2;
			}
		}
		if(post.charAt(0) != "\n") {
			post = "\n" + post;
		}
		newContent = pre + newContent + post;
	}
	if(params['line']) {
		pre = content.value.substring(0, selectionStart);
		post = content.value.substring(selectionStart, content.value.length);
		newSelectionStart = selectionStart + params['line'].length;
		if(content.value.charAt(selectionStart-1) != "\n") {
			pre += "\n";
			newSelectionStart++;
		}
		if(content.value.charAt(selectionStart) != "\n") {
			post = "\n" + post;
			newSelectionStart++;
		}
		newContent = pre + params['line'] + post;
		newSelectionEnd = newSelectionStart + selectedText.length;
	}
	
	content.value = newContent;
	content.selectionStart = newSelectionStart;
	content.selectionEnd = newSelectionEnd;
	content.focus();
	
	refreshPreview();
	
	return false;
}

function initToolbar() {
	if(!document.getElementById("toolbar")) {
		return;
	}
    toolbarItems = document.getElementById("toolbar-items");
	if(toolbarItems != null) {
		children = toolbarItems.children;
		for(i = 0; i < children.length; i++) {
			children[i].onclick = toolbarClickEvent;
		}
	}
	document.getElementById("toolbar").style.display = 'block';
}

var previewLoading = false;
var previewRefresh = false;

function refreshPreview() {
	if(previewLoading) {
		previewRefresh = true;
		return;
	}
	if(!document.getElementById("preview") || !document.getElementById("content")) {
		return;
	}
	
	livePreviewSwitch = document.getElementById("live-preview-switch");
	
	if(livePreviewSwitch.checked !== true) {
		return;
	}
	
	previewLoading = true;
	
	content = document.getElementById("content");
	previewContent = document.getElementById("preview-content");
	livePreviewLoader = document.getElementById("live-preview-loader");
	
	var httpRequest;
	if(window.XMLHttpRequest) {
		httpRequest = new XMLHttpRequest();
	} else if(window.ActiveXObject) {
		httpRequest = new ActiveXObject('Microsoft.XMLHTTP');
	} else {
		return;
	}
	httpRequest.onreadystatechange = function() {
		if(httpRequest.readyState == 4 && httpRequest.status == 200) {
			previewContent.innerHTML = httpRequest.responseText;
			if(previewContent.innerHTML == "") {
				previewContent.style.display = 'none';
			} else {
				previewContent.style.display = 'block';
			}
			if(previewRefresh) {
				previewRefresh = false;
				refreshPreview();
			}
			window.setTimeout('previewLoading = false', 500);
		}
		livePreviewLoader.style.display = 'none';
	}
	
	data = encodeURIComponent(csrfParam) + "=" + encodeURIComponent(csrfTocken);
	
	data +=  "&namespace=" + encodeURIComponent(namespace) + "&page=" + encodeURIComponent(page) + "&content=" + encodeURIComponent(content.value);
	
	httpRequest.open('POST', urlPrefix + 'preview', true);
	httpRequest.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	httpRequest.setRequestHeader("Content-Length", data.length);
	httpRequest.setRequestHeader("Connection", "close");
	httpRequest.send(data);
	livePreviewLoader.style.display = 'inline';
}

function scheduleRefresh() {
	if(!previewLoading && previewRefresh) {
		previewRefresh = false;
		refreshPreview();
	}
	window.setTimeout('scheduleRefresh()', 250);
}

function initLivePreview() {
	if(!document.getElementById("preview") || !document.getElementById("content")) {
		return;
	}
	document.getElementById("preview").style.display = 'block';
	
	// Check if browser supports AJAX
	if(!window.XMLHttpRequest && !window.ActiveXObject) {
		document.getElementById("preview").style.display = 'none';
		return;
	}
	
	content = document.getElementById("content");
	previewContent = document.getElementById("preview-content");
	livePreviewSwitch = document.getElementById("live-preview-switch");
	
	showLivePreview = false;
	cookies = document.cookie.split(';');
	for(i = 0; i < cookies.length; i++) {
		cookie = cookies[i].split(';')[0].split('=', 2);
		if(cookie[0].match('\s*live-preview\s*') && cookie[1].match('\s*true\s*')) {
			livePreviewSwitch.checked = true;
		}
	}
	
	previewContent.style.display = 'none';
	if(livePreviewSwitch.checked === true) {
		previewRefresh = true;
	}
	
	livePreviewSwitch.onchange = function(e) {
		previewContent.innerHTML = '';
		previewContent.style.display = 'none';
		if(livePreviewSwitch.checked === true) {
			previewRefresh = true;
		}
		expires = new Date((new Date()).getTime() + 31536000000); // 1 year
		document.cookie = 'live-preview=' + livePreviewSwitch.checked + ';expires=' + expires.toGMTString() + ';';
		return false;
	}
	
	content.onkeyup = function(e) {
		previewRefresh = true;
		return false;
	}
	
	window.setTimeout('scheduleRefresh()', 250);
}

var doUnlock = true;
function unlock() {
	var httpRequest;
	if(window.XMLHttpRequest) {
		httpRequest = new XMLHttpRequest();
	} else if(window.ActiveXObject) {
		httpRequest = new ActiveXObject('Microsoft.XMLHTTP');
	} else {
		return;
	}
	
	data = encodeURIComponent(csrfParam) + "=" + encodeURIComponent(csrfTocken);
	data += "&namespace=" + encodeURIComponent(namespace) + "&page=" + encodeURIComponent(page);

	httpRequest.open('POST', urlPrefix + 'unlock', false);
	httpRequest.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	httpRequest.setRequestHeader("Content-Length", data.length);
	httpRequest.setRequestHeader("Connection", "close");
	httpRequest.send(data);
}

window.onload = function() {
	initMetaVars();
	initEditButtons();
	initToolbar();
	initLivePreview();
};

window.onunload = function() {
	if(((action == 'edit') || (action == 'preview')) && doUnlock) {
		unlock();
	}
};
