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
	
	newSelectedText = null;
	
	if(params['enclosed']) {
		newSelectedText = params['enclosed'] + selectedText + params['enclosed'];
	}

	content.value = content.value.substring(0, selectionStart) + newSelectedText + content.value.substring(selectionEnd, content.value.length);
	content.selectionStart = selectionStart;
	content.selectionEnd = selectionStart + newSelectedText.length;
	content.focus();
}

function initToolbar() {
    toolbarItems = document.getElementById("toolbar-items");
	if(toolbarItems != null) {
		children = toolbarItems.children;
		for(i = 0; i < children.length; i++) {
			children[i].onclick = toolbarClickEvent;
		}
	}
}
window.onload = initToolbar;
