/* 
 * Raki - extensible rails-based wiki
 * Copyright (C) 2010 Florian Schwab & Martin Sigloch
 */

function toolbarClickEvent(e) {
	toolbarItem = (e.srcElement ? e.srcElement : e.target).parentNode;
	
	if (toolbarItem.tagName != "A") {
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
			previewLoading = false;
			if(previewRefresh) {
				previewRefresh = false;
				refreshPreview();
			}
		}
		livePreviewLoader.style.display = 'none';
	}
	
	var csrfParam;
	var csrfTocken;
	metaTags = document.getElementsByTagName("meta");
	for(i = 0; i < metaTags.length; i++) {
		name = metaTags[i].getAttribute('name');
		value = metaTags[i].getAttribute('content');
		if(name == 'csrf-param') {
			csrfParam = value
		} else if(name == 'csrf-token') {
			csrfTocken = value;
		}
	}
	data = csrfParam + "=" + csrfTocken.replace(/\+/g, '%2B');
	
	data += "&content=" + encodeURI(content.value) + "&parser=" + encodeURI("page");
	httpRequest.open('POST', '/preview', true);
	httpRequest.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	httpRequest.setRequestHeader("Content-Length", data.length);
	httpRequest.setRequestHeader("Connection", "close");
	httpRequest.send(data);
	livePreviewLoader.style.display = 'inline';
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
		refreshPreview();
	}
	
	livePreviewSwitch.onchange = function(e) {
		previewContent.innerHTML = '';
		previewContent.style.display = 'none';
		if(livePreviewSwitch.checked === true) {
			refreshPreview();
		}
		expires = new Date((new Date()).getTime() + 31536000000); // 1 year
		document.cookie = 'live-preview=' + livePreviewSwitch.checked + ';expires=' + expires.toGMTString() + ';';
		return false;
	}
	
	content.onkeyup = function(e) {
		refreshPreview();
		return false;
	}
}

function startup() {
	initToolbar();
	initLivePreview();
}

window.onload = startup;
