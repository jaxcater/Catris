# Năm map của Catris

**Tối đa năm map.** M01 bám căn phòng trong video. M02–M05 là đề xuất mở rộng. Mỗi map là một diorama có địa hình/sàn, props, rig ánh sáng, wind profile và ambience riêng; nhiều board dùng chung diorama.

## M01 — Góc Nắng

- **Cảm giác:** một buổi chiều ở nhà, yên và ấm. Đây là map chuẩn để so độ tương đồng với clip.
- **Palette:** mật ong, rose, kem, xanh lá trầm. Sàn gỗ ván dài và thảm hồng mềm có họa tiết lớn, đủ tương phản với mèo.
- **Bố cục dọc:** board ở trung tâm; cửa/rèm gợi ở phía trên; một cây lá lớn và góc đàn guitar/sách ở mép dưới. Khay mèo đặt trên phần thảm/sàn riêng dưới board, không che motif.
- **Hero props:** rèm linen có nếp, cây lá lớn trong chậu men, một góc guitar, gối mềm, chén nhỏ. Props ở rìa có thể bị crop có chủ ý; board thì không.
- **Lighting:** nắng nghiêng qua khung cửa, GI ấm, shadow thảm và mèo đúng độ cao.
- **Wind/VFX:** mép rèm và lá nhẹ; bụi ít trong nắng. Không gió làm lật cả cây.
- **Audio đề xuất:** room tone, vải nhẹ, chim xa rất thưa; foley thảm/gỗ mềm.
- **Kiểm tra riêng:** mèo trắng không cháy sáng; mèo đen vẫn rõ trong bóng khung cửa; toàn bộ board đọc được khi kéo.

## M02 — Dưới Tán Sồi

- **Cảm giác:** buổi picnic dưới cây; nhiều không khí hơn M01 nhưng vẫn là góc chơi gọn.
- **Palette:** xanh olive/sage, rơm kem, nâu vỏ cây, chấm hoa trắng.
- **Bố cục:** rễ/trunk gợi ở mép trên trái; thảm picnic ở khoảng cỏ phẳng giữa; hoa/cỏ thấp viền ngoài. Khay là phần picnic cùng cao độ logic.
- **Hero props:** một bộ rễ sculpt, cụm hoa nhỏ, giỏ picnic, acorn, bình nước. Không rải grass dày vào board.
- **Lighting:** nắng tán cây với bóng lá chậm; nền bóng dịu để mèo không lẫn vào cỏ.
- **Wind/VFX:** cỏ, lá và cành có stiffness khác nhau; vài lá rơi ngoài board. Dapple shadow không nhấp nháy nhanh.
- **Audio:** gió lá, chim ở xa, khoảng im lặng; không chorus chim phát đồng thời.
- **Kiểm tra riêng:** alpha foliage/overdraw, shadow animation và silhouette mèo trên nền xanh.

## M03 — Hiên Nhà Kính

- **Cảm giác:** hiên sáng sớm với cây được chăm sóc, bề mặt sạch và dịu.
- **Palette:** terracotta nhạt, men kem, sage, hồng hoa rất ít.
- **Bố cục:** cột/khung kính phía trên; chậu cao ở cạnh xa; dây leo và rèm mỏng ở rìa; thảm linen sage làm mặt board.
- **Hero props:** chậu gốm ba kích thước cùng family, cây dây leo, bình tưới nhỏ, chuông gió, rèm linen.
- **Lighting:** bóng khung nhà kính rõ nhưng dịu hơn M01; cloud modulation chậm, không thay exposure liên tục.
- **Wind/VFX:** rung dây chuông có điểm neo; dây leo sway; hạt bụi hoặc hạt bồ công anh thưa.
- **Audio:** lá, chim xa, chuông gió ngẫu nhiên có cooldown; chuông không được chói hoặc liên tục.
- **Kiểm tra riêng:** kính/transparency không tăng overdraw vô hạn; highlight men không hút mắt khỏi bàn.

## M04 — Ô Cửa Ngày Mưa

- **Cảm giác:** ở trong nhà khô ấm khi trời mưa bên ngoài; nơi trú yên tĩnh.
- **Palette:** gỗ nâu, vải dusty blue, nền ngoài cửa xanh xám, đèn amber.
- **Bố cục:** cửa kính ở một phần trên khung hình; lamp và sách ở rìa đối diện; board trên thảm sạch, khay trên đệm thấp.
- **Hero props:** khung cửa, mặt kính có giọt/vệt, đèn bàn, sách có mép trang, cốc có hơi nước rất nhẹ.
- **Lighting:** ánh sáng trời diffuse lạnh nhẹ cùng đèn ấm; lightmap/probe duy trì mặt mèo rõ.
- **Wind/VFX:** mưa ngoài kính và lá xa; hơi cốc đặt ngoài vùng chạm. Không có mưa xuyên thảm, giông chớp hoặc màn hình rung.
- **Audio:** rain bed mềm, vài giọt chạm mái; room tone ấm; giữ dải cao dễ nghe lâu.
- **Kiểm tra riêng:** lớp giọt mưa không trượt theo camera sai; giảm transparency/post nếu GPU nặng; không tạo cảnh u ám.

## M05 — Gác Mái Trăng

- **Cảm giác:** kết thúc ngày, yên ấm, có ánh trăng và chút lung linh xa.
- **Palette:** walnut, kem, indigo dịu, amber; tránh tím neon.
- **Bố cục:** một góc mái/cửa dormer phía trên, đèn nhỏ và chồng sách cạnh khay, thảm kem giữ board sáng.
- **Hero props:** cửa mái, đèn amber, sách/vải gấp, cây nhỏ; bầu trời chỉ là một mảng ngoài cửa.
- **Lighting:** key moonlight dịu và warm fill; bóng vẫn đọc, không phải toàn cảnh đen được cứu bằng emission.
- **Wind/VFX:** rèm rất ít, vài hạt sáng ở phía ngoài cửa. Không sao/đom đóm bay ngang mắt mèo.
- **Audio:** đêm yên, lá rất xa, nhạc ambient thưa; không insect loop quá sắc.
- **Kiểm tra riêng:** black cat và invalid/valid state đọc rõ; bloom không làm mất màu kem của thảm.

## Tái sử dụng và giới hạn

Dùng chung rig mèo, vật liệu cơ sở, hệ input, UI và phần logic. Có thể tái dùng chậu/sách/cốc với variation hợp lý, nhưng mỗi map cần ít nhất một hero prop và cấu trúc ánh sáng riêng. Đừng tạo map thứ sáu để chứa menu hoặc tutorial: menu/tutorial dùng M01 hoặc các view của map đã có.

Khi đổi map, chuyển cảnh ngắn khoảng 0,4–0,7 s và crossfade audio theo contract; không load cả năm map cùng lúc. Cutscene, traversal ngoài bàn và thời tiết ngẫu nhiên không thuộc phạm vi mặc định.
