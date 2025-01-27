import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { PrismaService } from '../prisma/prisma.service';
import { User } from '@prisma/client';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {

  constructor(private readonly prisma: PrismaService) {}

  async create(data: CreateUserDto): Promise<User> {
    const { address, email, username } = data;

    // 1. Check if the address already exists in the database
    const existingUserByAddress = await this.prisma.user.findUnique({
      where: { address },
    });
    if (existingUserByAddress) {
      throw new BadRequestException('User already registered');
    }

    // 2. Validate if the address is a valid Starknet address
    if (!this.isValidStarknetAddress(address)) {
      throw new BadRequestException('Invalid Starknet address');
    }

    // 3. Ensure email is unique (if provided)
    if (email) {
      const existingUserByEmail = await this.prisma.user.findUnique({
        where: { email },
      });
      if (existingUserByEmail) {
        throw new BadRequestException('Email is already in use');
      }
    }

    // 4. Ensure username is unique (if provided)
    if (username) {
      const existingUserByUsername = await this.prisma.user.findUnique({
        where: { username },
      });
      if (existingUserByUsername) {
        throw new BadRequestException('Username is already in use');
      }
    }

    // 5. Save the user to the database
    const newUser = await this.prisma.user.create({
      data: {
        address,
        email,
        username,
        isVerified: false, // Set default value for isVerified
      },
    });

    return newUser;
  }
  }

    // 3. Ensure email is unique (if provided)
 


  

  findAll() {
    return `This action returns all users`;
  }

  findOne(id: number) {
    return `This action returns a #${id} user`;
  }

  update(id: number, updateUserDto: UpdateUserDto) {
    return `This action updates a #${id} user`;
  }

  remove(id: number) {
    return `This action removes a #${id} user`;
  }
}
