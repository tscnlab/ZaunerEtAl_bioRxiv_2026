-- Convert remaining HTML figure markup after Quarto normalizes its structure.
function RawBlock(block)
  if FORMAT:match("docx") and block.format:match("html")
      and (block.text:match("<figure") or block.text:match("<img")) then
    return pandoc.read(block.text, "html").blocks
  end
end

function RawInline(inline)
  if FORMAT:match("docx") and inline.format:match("html")
      and inline.text:match("<img") then
    local blocks = pandoc.read(inline.text, "html").blocks
    if #blocks == 1 and (blocks[1].t == "Para" or blocks[1].t == "Plain") then
      return blocks[1].content
    end
  end
end
