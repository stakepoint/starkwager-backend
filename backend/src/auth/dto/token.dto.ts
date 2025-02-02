import { UserRoleEnum } from 'src/users/enums/user.enum';

export class UserTokenDto {
  address: string;
  sub: string;
  role: UserRoleEnum;
}
