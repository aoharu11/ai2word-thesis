function Table(el)
  -- 칸(Column)이 2개인 표만 찾음 (수식 상자)
  if #el.colspecs == 2 then
    -- 첫 번째 칸(수식) 너비: 88.2%
    el.colspecs[1][2] = 0.882
    -- 두 번째 칸(번호) 너비: 11.8%
    el.colspecs[2][2] = 0.118
    
    -- 첫 번째 칸 정렬: 가운데 (Center)
    el.colspecs[1][1] = 'AlignCenter'
    -- 두 번째 칸 정렬: 가운데 (Center) - 원본과 동일하게
    el.colspecs[2][1] = 'AlignCenter'
    
    return el
  end
end
