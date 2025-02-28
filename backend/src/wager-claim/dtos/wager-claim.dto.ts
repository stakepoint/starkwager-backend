import { IsEnum, IsNotEmpty, IsString, IsUUID } from 'class-validator';

enum WagerClaimStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
}

export default WagerClaimStatus;

export class CreateWagerClaimDto {
  @IsString()
  @IsUUID()
  @IsNotEmpty()
  wagerId: string;

  @IsString()
  @IsNotEmpty()
  @IsUUID()
  claimedById: string;

  @IsString()
  @IsNotEmpty()
  @IsEnum(WagerClaimStatus)
  status: string;
}

export class RejectWagerClaimDto {
  @IsString()
  @IsUUID()
  @IsNotEmpty()
  id: string;

  @IsString()
  @IsNotEmpty()
  reason: string;

  @IsString()
  @IsNotEmpty()
  @IsEnum(WagerClaimStatus)
  status: string;

  @IsString()
  proofLink: string;

  @IsString()
  proofFile: string;
}
