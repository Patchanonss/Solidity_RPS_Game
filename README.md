# Solidity Rock, Paper, Scissors, Lizard, Spock (RPSLS)
## รายละเอียดโปรเจค
เกม RPSLS ที่ใช้ Commit-Reveal เพื่อป้องกัน front-running และใช้ระบบ timeout เพื่อป้องกันการล็อกเงิน

## 📜 Solidity Contracts
- **RPSLS.sol**: Smart contract หลักของเกม
- **CommitReveal.sol**: จัดการ Commit-Reveal Scheme
- **TimeUnit.sol**: จัดการเรื่อง Timeout

## 🔒 ป้องกันการล็อกเงิน
- ถ้า `player1` ไม่มาภายใน 5 นาที `player0` สามารถถอนเงินคืนได้
- ถ้าผู้เล่นไม่ reveal ภายใน 5 นาที อีกคนสามารถ claim ชัยชนะได้

## 🔑 Commit-Reveal Choice
- ผู้เล่นต้อง Commit (`keccak256(choice + secret)`)
- จากนั้นต้อง Reveal (`choice, secret`)

## 🕒 จัดการความล่าช้า
- ใช้ `startTimer(5 minutes)` เมื่อ `player0` เข้าเกม
- ใช้ `revealDeadline` ตรวจสอบเวลาที่ต้อง reveal

## 🏆 การตัดสินผู้ชนะ
- `keccak256(abi.encodePacked(choice, secret))` ตรวจสอบค่า reveal
- `_checkWinnerAndPay()` ตัดสินและจ่ายเงินให้ผู้ชนะ
