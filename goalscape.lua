-- Invoke with: pandoc -t goalscape.lua --template default.goalscape --filter ./pandoc-filter-goalscape.php test.md > test.gsp

local DEBUG = {
  structure = false,
  text = false -- TODO
}

local WEIGHT = {
  even = "even",
  length = "length",
  children = "children"
}

local escape, attributes, pipe, html_align, tabbed, log
local GSGoal, GSNote, GSAttachment



-- A tree structure for nesting headers and their content
function GSGoal(init)
  local self = {
    type = "Goal",
    name = "",
    parent = nil,
    children = {},
    weight = WEIGHT.children
  }

  -- merge init into self
  local k,v
  for k,v in pairs(init) do self[k] = v end
  
  function self.level()
    if not self.parent then return 0 end
    return self.parent.level() + 1
  end
  
  function self.length()
    local l = string.len(self.name)
    local k,v
    for k,v in pairs(self.children) do
      l = l + v.length()
    end
    return l
  end
  
  function self.subgoals(deep)
    local subgoals = {}
    local k,v, k2, v2
    for k,v in pairs(self.children) do
      if v.type == 'Goal' then
        table.insert(subgoals, v)
        if deep then
          local subsubgoals = v.subgoals(deep)
          for k2,v2 in pairs(subsubgoals) do
            table.insert(subgoals, v2)
          end
        end
      end
    end
    return subgoals
  end
  
  -- Importance in GoalScape controls the size of the wedge
  function self.importance()
    local imp = 100
    if self.parent then
      local even = 100 / #self.parent.subgoals(false)
      local pweight = self.parent.weight
      if pweight == WEIGHT.length then
        imp = 100 * self.length() / self.parent.length()
      elseif pweight == WEIGHT.children then
        local subs = #self.subgoals(true) + 1
        imp = 100 * subs / #self.parent.subgoals(true)
      elseif pweight == WEIGHT.even then
        imp = even
      else
        io.stderr:write(string.format("WARNING: Unknown weight %s, using 'even'\n", pweight));
        imp = even
      end
    end
    return string.format("%.2f", imp)
  end
  
  function self.addNote(s)
    self.addChild(GSNote({name = s}))
  end
  
  function self.addAttachment(s, url)
    self.addChild(GSAttachment({name = s}, url))
  end
  
  function self.addChild(c)
    if c then
      table.insert(self.children, c)
      c.parent = self
      c.weight = self.weight
    end
  end
  
  function self.optimize()
    self.squishNotes()
    self.squishAttachments()
    self.squishTree()
  end
  
  function self.squishNotes()
    if #self.children > 1 then
      -- Squish consequtive notes into a single note
      local new_children = {}
      local squished = {}
      local k,v
      for k,v in pairs(self.children) do
        if v.type ~= 'Note' then
          -- Insert squish notes first
          if #squished > 0 then
            table.insert(new_children, GSNote({name = table.concat(squished,'<P></P>')}))
            squished = {}
          end 
          table.insert(new_children, v)
        else
          table.insert(squished, v.name)
        end
      end
      if #squished > 0 then
        table.insert(new_children, GSNote({name = table.concat(squished,'<P></P>')}))
      end
      self.children = new_children
    end
    -- Recurse after squishing
    if #self.children > 0 then
      local k,v
      for k,v in pairs(self.children) do
        v.squishNotes()
      end
    end
  end
  
  function self.squishAttachments()
    -- TODO
  end
  
  function self.squishTree()
    -- TODO
  end
  
  function self.toTabIndentedList()
    local str = ""
    local k,v
    for k,v in pairs(self.children) do
      str = str .. v.toTabIndentedList()
    end
  
    local tabs = string.rep('\t',self.level())
    return tabs .. self.name .. '\t' .. self.importance() .. '\n' .. str
  end

  function self.toGoalScapeXML()
    local str = ""
        
    -- Recurse Tree and renest if necessary
    local k,v
    if #self.children == 1 then
      for k,v in pairs(self.children) do
        str = str .. v.toGoalScapeXML()
      end
    elseif #self.children > 1 then  
      for k,v in pairs(self.children) do
        if k == 1 and v.type == "Note" then
          -- noop: keep notes under this goal rather than creating a subgoal 
        elseif v.type ~= "Goal" then
          -- Renest
          local leaf = GSGoal({name = " ", parent = self}) -- DEBUG use "*" to see better
          leaf.addChild(v)
          self.children[k] = leaf
          v = leaf
        end
        
        str = str .. v.toGoalScapeXML()
      end
    end
    
    local attr = {}
    attr['name'] = string.sub(self.name, 0, 255)
    attr['importance'] = self.importance()
    attr['progress']   = "0.00"
    attr['relativeFontSize'] = "0"
    attr['notesTabIndex'] = "0"
    local tabs = string.rep('\t',self.level())
    return tabs .. '<goal' .. attributes(attr) .. '>\n' .. str .. '\n' .. tabs .. '</goal>\n'
  end

  -- return the instance
  return self
end

function GSNote(init)
  local self = GSGoal(init)
  self.type = "Note"
  
  function self.length()
    return string.len(self.name)
  end
  
  function self.addNote(s)
    io.stderr:write("WARNING: Trying to create note on a Note\n");
  end
  
  function self.addChild(c)
    io.stderr:write("WARNING: Trying to add child on a Note\n");
  end
  
  function self.toTabIndentedList()
    local tabs = string.rep('\t',self.level())
    return tabs .. "NOTE" .. '\n'
  end
  
  function self.toGoalScapeXML()
    local tabs = string.rep('\t',self.level())
    return tabs .. '<notes><![CDATA[<HTML><BODY>' .. self.name .. '</BODY></HTML>]]></notes>\n'
  end
  
  return self
end

function GSAttachment(init, url)
  local self = GSGoal(init)
  self.type = "Attachment"
  local purl = url
  
  function self.length()
    return 1000
  end
  
  function self.addNote(s)
    io.stderr:write("WARNING: Trying to create note on an Attachment\n");
  end
  
  function self.addChild(c)
    io.stderr:write("WARNING: Trying to add child on an Attachment\n");
  end
  
  function self.toTabIndentedList()
    local tabs = string.rep('\t',self.level())
    return tabs .. "ATTACHMENT" .. '\n'
  end
  
  function self.toGoalScapeXML()    
    local tabs = string.rep('\t',self.level())
    return tabs .. '<attachments><attachment name="' .. escape(self.name,true) .. '" url="' .. escape(purl,true) .. '"/></attachments>\n'
  end
  
  return self
end



-- Table to store footnotes, so they can be included at the end.
local notes = {}

local root = GSGoal({name = "ROOT"})
local branch = root



-------------------
-- HELPER FUNCTIONS
-------------------

-- Character escaping
function escape(s, in_attribute)
  return s:gsub("[<>&\"']",
    function(x)
      if x == '<' then
        return '&lt;'
      elseif x == '>' then
        return '&gt;'
      elseif x == '&' then
        return '&amp;'
      elseif x == '"' then
        return '&quot;'
      else
        return x
      end
    end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= "" then
      table.insert(attr_table, ' ' .. x .. '="' .. escape(y,true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Run cmd on a temporary file containing inp and return result.
function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " " .. tmp,"r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end

-- Convert pandoc alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
function html_align(align)
  if align == 'AlignLeft' then
    return 'left'
  elseif align == 'AlignRight' then
    return 'right'
  elseif align == 'AlignCenter' then
    return 'center'
  else
    return 'left'
  end
end

local function tabbed(s)
  local tabs = string.rep('\t', branch.level())
  return "" .. tabs .. s .. '\n'
end

function log(s)
  if DEBUG.structure then
    io.stderr:write(tabbed(s))
  end
end




-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.
function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  
  -- Fixup the Tree a bit…
  root.optimize()
  -- Hoist
  if #root.children == 1 and root.children[1].type == 'Goal' then
    root = root.children[1]
    root.parent = nil
  end
  
  --add(root.toTabIndentedList())
  --add("----------------------------")
  add(root.toGoalScapeXML())
  return table.concat(buffer,'\n') .. '\n'
end







-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Blocksep()
  log("Blocksep")
  return "\n"
end

function Str(s)
  log("Str")
  return s
end

function Space()
  log("Space")
  return " "
end

function SoftBreak()
  log("SoftBreak")
  return "\n"
end

function LineBreak()
  log("LineBreak")
  return "<BR/>"
end

function Emph(s)
  log("Emph")
  return "<I>" .. s .. "</I>"
end

function Strong(s)
  log("Strong")
  return "<B>" .. s .. "</B>"
end

function Subscript(s)
  log("Subscript")
  return "<sub>" .. s .. "</sub>"
end

function Superscript(s)
  log("Superscript")
  return "<sup>" .. s .. "</sup>"
end

function SmallCaps(s)
  log("SmallCaps")
  return '<span style="font-variant: small-caps;">' .. s .. '</span>'
end

function Strikeout(s)
  log("Strikeout")
  return '<del>' .. s .. '</del>'
end

function Link(s, src, tit, attr)
  log("Link")
  return '<A HREF="' .. escape(src,true) .. '" TARGET="_blank">' .. s .. '</A>'
end

function Image(s, src, tit, attr)
  log("Image")
  --branch.addAttachment(tit, src) -- Images as Attachment nodes
  --branch.addNote(Para(Link('<IMG src="' .. escape(src,true) .. '"/>', src, tit, attr))) -- Images embedded in Notes with link
  branch.addNote(Para(Link('IMAGE ' .. tit, src, tit, attr))) -- Images as a text link
  return ''
end

function Code(s, attr)
  log("Code")
  return "<code" .. attributes(attr) .. ">" .. escape(s) .. "</code>"
end

function InlineMath(s)
  log("InlineMath")
  return "\\(" .. escape(s) .. "\\)"
end

function DisplayMath(s)
  log("DisplayMath")
  return "\\[" .. escape(s) .. "\\]"
end

function Note(s)
  log("Note")
  local num = #notes + 1
  -- insert the back reference right before the final closing tag.
  s = string.gsub(s,
          '(.*)</', '%1 <a href="#fnref' .. num ..  '">&#8617;</a></')
  -- add a list item with the note to the note table.
  table.insert(notes, '<li id="fn' .. num .. '">' .. s .. '</li>')
  -- return the footnote reference, linked to the note.
  return '<a id="fnref' .. num .. '" href="#fn' .. num ..
            '"><sup>' .. num .. '</sup></a>'
end

function Span(s, attr)
  log("Span")
  --return "<FONT" .. attributes(attr) .. ">" .. s .. "</FONT>"
  return s
end

function RawInline(format, str)
  log("RawInline")
  if format == "html" then
    return str
  end
  return ''
end

function Cite(s, cs)
  log("Cite")
  local ids = {}
  for _,cit in ipairs(cs) do
    table.insert(ids, cit.citationId)
  end
  return "<span class=\"cite\" data-citation-ids=\"" .. table.concat(ids, ",") ..
    "\">" .. s .. "</span>"
end

function Plain(s)
  log("Plain")
  return s
end

function Para(s)
  log("Para")
  branch.addNote("<P>" .. s .. "</P>")
  return ''
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
  log("Header")
  
  local leaf = nil
  local depth = branch.level()
  
  -- Find the branch where this new header will be a child
  if lev > depth then
    while branch.level() < lev-1 do
      -- Create intermediate levels to maintain structure
      leaf = GSGoal({name = "INTERMEDIATE"})
      branch.addChild(leaf)
      branch = leaf
    end
  else
    while branch.level() >= lev do
      branch = branch.parent
    end
  end
  
  leaf = GSGoal({name = s})
  branch.addChild(leaf)
  branch = leaf
  
  if WEIGHT[attr['class']] ~= nil then
    branch.weight = attr['class']
  end

  return ""
end

function BlockQuote(s)
  log("BlockQuote")
  return "<blockquote>\n" .. s .. "\n</blockquote>"
end

function HorizontalRule()
  log("HorizontalRule")
  return "<HR/>"
end

function LineBlock(ls)
  log("LineBlock")
  return Para(table.concat(ls, '<BR/>\n'))
end

function CodeBlock(s, attr)
  log("CodeBlock")
  -- If code block has class 'dot', pipe the contents through dot
  -- and base64, and include the base64-encoded png as a data: URL.
  if attr.class and string.match(' ' .. attr.class .. ' ',' dot ') then
    local png = pipe("base64", pipe("dot -Tpng", s))
    return '<img src="data:image/png;base64,' .. png .. '"/>'
  -- otherwise treat as code (one could pipe through a highlighter)
  else
    return "<pre><code" .. attributes(attr) .. ">" .. escape(s) ..
           "</code></pre>"
  end
end

function BulletList(items)
  log("BulletList")
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<LI>" .. item .. "</LI>")
  end
  branch.addNote("<UL>" .. table.concat(buffer) .. "</UL>")
  return ''
end

function OrderedList(items)
  log("OrderedList")
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<LI>" .. item .. "</LI>")
  end
  branch.addNote("<OL>" .. table.concat(buffer) .. "</OL>")
  return ''
end

function CaptionedImage(src, tit, caption, attr)
  log("CaptionedImage")
  return Image("", src, caption, attr)
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  log("Table")
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("<table>")
  if caption ~= "" then
    add("<caption>" .. caption .. "</caption>")
  end
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
      add('<col width="' .. string.format("%d%%", w * 100) .. '" />')
    end
  end
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    table.insert(header_row,'<th align="' .. align .. '">' .. h .. '</th>')
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add('<tr class="header">')
    for _,h in pairs(header_row) do
      add(h)
    end
    add('</tr>')
  end
  local class = "even"
  for _, row in pairs(rows) do
    class = (class == "even" and "odd") or "even"
    add('<tr class="' .. class .. '">')
    for i,c in pairs(row) do
      add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')
    end
    add('</tr>')
  end
  add('</table')
  return table.concat(buffer,'\n')
end

function RawBlock(format, str)
  log("RawBlock")
  if format == "html" then
    return str
  end
  return ''
end

function Div(s, attr)
  log("Div")
  return "<P" .. attributes(attr) .. ">\n" .. s .. "</P>"
end




-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n", key))
    return function() return "" end
  end
setmetatable(_G, meta)

