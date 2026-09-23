-- Normalize image-bearing tables before Quarto processes their HTML.
function RawBlock(block)
  if FORMAT:match("docx") and block.format == "openxml"
      and block.text:match("<w:tbl") then
    -- Tables use single spacing even when the manuscript body is double spaced.
    local text = block.text:gsub("<w:spacing[^>]*/>",
      '<w:spacing w:before="0" w:after="40" w:line="240" w:lineRule="auto"/>')
    return pandoc.RawBlock("openxml", text)
  end
  if FORMAT:match("docx") and block.format:match("html")
      and block.text:match("data%-word%-image%-width") then
    local document = pandoc.read(block.text, "html")
    -- Each wrapper may contain its own panel layout and thumbnail size.
    document = document:walk({ Div = function(div)
      local image_width = div.attributes["word-image-width"]
      local column_widths = div.attributes["word-column-widths"]
      if not image_width then return nil end
      local widths = {}
      for value in (column_widths or ""):gmatch("[^,]+") do
        table.insert(widths, tonumber(value))
      end
      return div:walk({
        Image = function(image)
          image.attributes.width = image_width
          image.attributes.height = nil
          return image
        end,
        Table = function(tbl)
          if #tbl.colspecs == #widths then
            for i, spec in ipairs(tbl.colspecs) do
              tbl.colspecs[i] = {pandoc.AlignLeft, widths[i]}
            end
          end
          return tbl
        end
      })
    end })
    return document.blocks
  end
end
