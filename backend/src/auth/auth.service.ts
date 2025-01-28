import { Injectable } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { CreateUserDto } from 'src/users/dto/create-user.dto';

@Injectable()
export class AuthService {
  constructor(private readonly usersService: UsersService) {}

  async createOrLogin(createUserDto: CreateUserDto) {
    const { address } = createUserDto;

    // TODO: Add signature validation here
    // Example: Validate the user's signature using their address
    // if (!this.isValidSignature(address, signature)) {
    //   throw new BadRequestException('Invalid signature');
    // }

    // Check if the user already exists
    const existingUser = await this.usersService.findOneByAddress(address);

    if (existingUser) {
      // TODO: Implement login logic here JWT etc.
      return {
        message: 'User logged in successfully',
        user: existingUser,
      };
    }

    const newUser = await this.usersService.create(createUserDto);

    return {
      message: 'User created successfully',
      user: newUser,
    };
  }

  // TODO: Implement signature validation
  private isValidSignature(address: string, signature: string[]): boolean {
    //Implement signature validation here
    return true; // Placeholder
  }
}
