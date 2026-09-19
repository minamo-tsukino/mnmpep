-- mermaid.lua (HTML + DOCX + クロスプラットフォーム対応)

local pipe = pandoc.pipe

-- OS 判定
local function is_windows()
  return package.config:sub(1,1) == "\\"
end

-- mmdc のパスを OS ごとに解決
local function resolve_mmdc()
  if is_windows() then
    local user = os.getenv("USERPROFILE")
    return user .. "\\AppData\\Roaming\\npm\\mmdc.cmd"
  else
    return "mmdc"
  end
end

-- 安全な一時ファイル名を作る
local function temp_png()
  local tmp = os.getenv(is_windows() and "TEMP" or "TMPDIR") or "/tmp"
  local sep = is_windows() and "\\" or "/"
  return tmp .. sep .. "mermaid_" .. tostring(os.time()) .. ".png"
end

function CodeBlock(block)
  -- Mermaid 以外は何もしない
  if not block.classes:includes("mermaid") then
    return nil
  end

  -- HTML 出力
  if FORMAT:match("html") then
    return pandoc.RawBlock("html",
      '<pre class="mermaid">\n' ..
      block.text ..
      '\n</pre>'
    )
  end

  -- DOCX 出力（Mermaid がある場合のみ mmdc を使う）
  if FORMAT:match("docx") then
    -- mmdc が存在しない場合はスキップ（Mermaid を画像化しない）
    local mmdc = resolve_mmdc()
    local ok = os.execute(mmdc .. " -h >nul 2>&1")

    if not ok then
      -- mmdc が無い環境 → Mermaid をそのままコードブロックとして残す
      return pandoc.CodeBlock(block.text)
    end

    -- mmdc がある → PNG 生成
    local fname = temp_png()

    pipe(mmdc, {
      "-i", "-",
      "-o", fname,
      "-t", "neutral",
      "-b", "white"
    }, block.text)

    return pandoc.Para({
      pandoc.Image({}, fname)
    })
  end

  return nil
end
