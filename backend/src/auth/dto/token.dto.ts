import { Role } from 'src/common/enums/roles.enum';

export class UserTokenDto {
  address: string;
  sub: string;
  role: Role;
}

export class RefreshTokenDto {
  refreshToken: string;
}
