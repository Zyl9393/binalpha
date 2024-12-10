local dlgConf = Dialog("Binary Alpha")

local numPixelsMadeOpaque = 0
local numPixelsMadeTransparent = 0
local numCelsTouched = 0

function BinalphaImage(cel)
	local image = cel.image
	local newImage = nil
	local alphaThreshold = dlgConf.data.alphaThreshold
	for y = 0, image.height do
		for x = 0, image.width do
			local pixel = image:getPixel(x, y)
			local a = (pixel & 0xff000000) >> 24
			if (a ~= 0 or alphaThreshold <= 0) and (a ~= 255 or alphaThreshold > 255) then
				if newImage == nil then
					newImage = image:clone()
				end
				if a >= alphaThreshold then
					newImage:drawPixel(x, y, pixel | 0xff000000)
					numPixelsMadeOpaque = numPixelsMadeOpaque + 1
				else
					newImage:drawPixel(x, y, pixel & 0x00ffffff)
					numPixelsMadeTransparent = numPixelsMadeTransparent + 1
				end
			end
		end
	end
	if newImage ~= nil then
		numCelsTouched = numCelsTouched + 1
		cel.image = newImage
	end
end

function BinalphaLayer(layer)
	if layer.isGroup then
		for i, subLayer in ipairs(layer.layers) do
			BinalphaLayer(subLayer)
		end
	elseif layer.isImage and layer.isTransparent then
		for i, cel in ipairs(layer.cels) do
			BinalphaImage(cel)
		end
	end
end

function BinalphaRun()
	local sprite = app.site.sprite;
	if dlgConf.data.rbAll then
		for i = 1, #sprite.cels do
			BinalphaImage(sprite.cels[i])
		end
	elseif dlgConf.data.rbLayer then
		for i = 1, #app.site.layer.cels do
			BinalphaImage(app.site.layer.cels[i])
		end
	elseif dlgConf.data.rbFrame then
		local frame = app.site.frame
		for i = 1, #sprite.cels do
			local cel = sprite.cels[i]
			if cel.frame == frame then
				BinalphaImage(cel)
			end
		end
	elseif dlgConf.data.rbCel then
		BinalphaImage(app.site.cel)
	end
	dlgConf:close()
	
	app.refresh() -- Don't wait for dlgSummary to close to repaint the canvas.
	
	local dlgSummary = Dialog("Binary Alpha Summary")
	dlgSummary:label{label="Pixels made opaque", text=tostring(numPixelsMadeOpaque)}
	dlgSummary:newrow()
	dlgSummary:label{label="Pixels made transparent", text=tostring(numPixelsMadeTransparent)}
	dlgSummary:newrow()
	dlgSummary:label{label="Cels touched", text=tostring(numCelsTouched)}
	dlgSummary:newrow()
	dlgSummary:button{text="Close", onclick=function() dlgSummary:close() end}
	dlgSummary:show()
end

function BinalphaRunTransaction()
	app.transaction("Binary Alpha", BinalphaRun)
end

dlgConf:radio{id="rbAll", label="Choose what to affect", text="Entire sprite", selected=true}
dlgConf:newrow()
dlgConf:radio{id="rbLayer", text="Current layer"}
dlgConf:newrow()
dlgConf:radio{id="rbFrame", text="Current frame"}
dlgConf:newrow()
dlgConf:radio{id="rbCel", text="Current cel"}
dlgConf:newrow()
dlgConf:number{id="alphaThreshold", label="Alpha Threshold", text="128"}
dlgConf:newrow()
dlgConf:button{text="Run", onclick=BinalphaRunTransaction}
dlgConf:button{text="Cancel", onclick=function() dlgConf:close() end}
dlgConf:show()

return 0;
