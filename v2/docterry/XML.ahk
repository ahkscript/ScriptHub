; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=138365
; Author: docterry

#Requires AutoHotkey v2.0

class XML
{
/*	XML class for AHK v2 (2025) by docterry

	new() = return new XML document
	addElement() = append new element to node object
	insertElement() = insert new element above node object
	getText() = return element text if present
	setText() = set element text, create element if needed
	getAtt() = get attribute
	setAtt() = set attributes
	copyNode() = clone a node and append to another node
	moveNode() = clode a node and move to another node 
	removeNode() = remove a node
	findXPath() = return xpath to node (needs work)
	transformXML() = format XML stream
	saveXML() = saves XML with filename param or original filename
*/
	__New(src:="") {
		this.doc := ComObject("Msxml2.DOMDocument.6.0")
		if (src) {
			if (src ~= "s)^<.*>$") {
				this.doc.loadXML(src)
			} 
			else if FileExist(src) {
				this.doc.load(src)
				this.filename := src
			}
			if !(this.doc.hasChildNodes) {
				throw ValueError("Cannot initialize XML object. Parameter does not appear to contain valid XML.")
			}
		} else {
			src := "<?xml version=`"1.0`" encoding=`"UTF-8`"?><root />"
			this.doc.loadXML(src)
		}
	}

	__Call(method, params) {
		if !ObjHasOwnProp(XML,method) {
			try {
				return this.doc.%method%(params[1])
			}
			catch as err {
				throw ValueError(this.errString(err))
			} 
		}
	}

	addElement(node,child,params*) {
	/*	Appends new child to node object
		Node can be node object or XPATH
		Params:
			text gets added as text
			@attr1='abc', trims outer '' chars
			@attr2='xyz'
	*/
		node := this.isNode(node)
		try {
			IsObject(node)
		} 
		catch as err {
			throw ValueError(this.errString(err))
		} 
		else {
			newElem := this.doc.createElement(child)
			for p in params {
				if IsObject(p) {
					for key,val in p.OwnProps() {
						newElem.setAttribute(key,val)
					}
				} else {
					newElem.text := p
				}
			}
			return node.appendChild(newElem)
		}
	}

	insertElement(node,new,params*) {
	/*	Inserts new sibling above node object
		Object must have valid parentNode
	*/
		node := this.isNode(node)
		try {
			IsObject(node.ParentNode)
		}
		catch as err {
			throw ValueError(this.errString(err))
		} 
		else {
			newElem := this.doc.createElement(new)
			for p in params {
				if IsObject(p) {
					for key,val in p.OwnProps() {
						newElem.setAttribute(key,val)
					} 
				} else {
					newElem.text := p
				}
			}
			return node.parentNode.insertBefore(newElem,node)
		}
	}

	getText(node) {
	/*	Checks whether node exists to fetch text
		Prevents error if no text present
	*/
		node := this.isNode(node)
		try {
			return node.text
		} catch as err {
			throw ValueError(this.errString(err))
		}
	}

	setText(node,txt) {
	/*	Set text value for a node
		If node does not exist, create node first
		Must have valid parent node
	*/
		node := this.isNode(node)
		parent := node.parentNode
		child := node.nodeName
		try {
			node.text := txt
		}
		catch {
			newElem := this.doc.createElement(child)
			newElem.text := txt
			parent.appendChild(newElem)
		}
	}

	setAtt(nodein,atts) {
	/*	Set attributes of an existing node
		atts object can contain multiple attribute pairs
	*/
		node := this.isNode(nodein)
		for att,val in atts.OwnProps()
		{
			try node.setAttribute(att,val)
		}
	}

	getAtt(nodein,att) {
	/*	Get attribute for existing node
		Here mostly for consistency, to match setAtt
	*/
		node := this.isNode(nodein)
		try {
			return node.getAttribute(att)
		}
		catch {
			return ""
		}
	}

	renameNode(nodein,newName) {
	/*	Renames a node
		Retains all attributes and children
	*/
		node := this.isNode(nodein)
		newnode := this.doc.createElement(newName)

		while node.hasChildNodes {
			newnode.appendChild(node.firstChild)
		}
		
		while (node.attributes.length > 0) {
			newnode.setAttributeNode(node.removeAttributeNode(node.attributes[0]))
		}

		try {
			node.parentNode.replaceChild(newnode,node)
		} 
		catch as err {
			throw ValueError(this.errString(err))
		}
	}

	copyNode(nodein,dest) {
	/*	Copies a clone of node to destination node
	*/
		node := this.isNode(nodein)
		destnode := this.isNode(dest)

		try {
			copy := node.cloneNode(true)
			x := destnode.nodeName
			y := destnode.text
			destnode.appendChild(copy)
		}
		catch as err {
			throw ValueError(this.errString(err))
		}
	}

	moveNode(nodein,dest) {
	/*	Moves a clone of node to destination node
	*/
		node := this.isNode(nodein)
		destnode := this.isNode(dest)

		try {
			copy := node.cloneNode(true)
			destnode.appendChild(copy)
			node.parentNode.removeChild(node)
		} 
		catch as err {
			throw ValueError(this.errString(err))
		}
	}

	removeNode(nodein) {
	/*	Removes node
	*/
		node := this.isNode(nodein)

		try node.parentNode.removeChild(node)
	}
	
	saveXML(fname:="") {
	/*	Saves XML
		to fname if passed, otherwise to original filename
	*/
		if (fname="") {
			fname := this.filename
		}
		this.doc.save(fname)
	}

	transformXML() {
	/*	Formats XML stream using stylesheet
	*/ 
		this.doc.transformNodeToObject(this.style(), this.doc)
	}
	
	findXPath(node) {
	/*	Returns rough xpath of node
	*/
		build := ""

		while (node.parentNode) {
			switch node.nodeType {
				case 1:																	; 1=Element
				{
					index := this.elementIndex(node)
					build := "/" node.nodeName "[" index "]" . build
					node := node.parentNode
				} 
				case 2:																	; 2=Attribute
				{

				}
				case 3:																	; 3=Text
				{

				}
				default:
					
			}
		}
		return build
	}

	

/*	====================================================================================
	INTERNAL SUPPORT FUNCTIONS
*/
	errString(err) {
		return "Error: " err.Message "`n"
			. "What: " err.What "`n"
			. "Where: " err.Extra "`n"
			. "File: " err.File "`n"
			. "Line: " err.Line "`n"
			. "Stack: " err.Stack
	}
	isNode(node) {
		if (node is String) {
			try node := this.doc.selectSingleNode(node)
		}
		try {
			return node
		}
	}

	elementIndex(node) {
		loop {
			try {
				node := node.previousSibling
				idx := A_Index
			} catch {
				break
			}
		}
		return idx
	}

	style() {
		static xsl
		
		try {
			IsObject(xsl)
		}
		catch {
			xsl := ComObject("Msxml2.DOMDocument.6.0")
			style := "
			(LTrim
			<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
			<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
			<xsl:template match="@*|node()">
			<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
			<xsl:for-each select="@*">
			<xsl:text></xsl:text>
			</xsl:for-each>
			</xsl:copy>
			</xsl:template>
			</xsl:stylesheet>
			)"
			xsl.loadXML(style), style := ""
		}
		return xsl
	}
}